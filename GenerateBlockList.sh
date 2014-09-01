#!/bin/bash 
#
# GenerateBlockList.sh
# version 1.2
#
# Features:
# - pulling out ip addresses for each spam comment in wordpress database
# - check country, cidr and calculate cidr for given ip (if not found)
# - generate block entries for CHINA, RUSSIA and other countries
#  You can add generated entries to your .htaccess or main apache comfig file (preferred method).
# 
# Prerequisites:
# 1. bash, whois, ipcalc, grep, sort, awk, perl
# 2. sudo privileges
# 3. connection to database - this script has to be executed on the vps from which you'll be 
# connecting to WP database.
#
# TODO:	1. Enable support for multiple WP databases
#			 		2. Manage external BlockList, compare current list and update it with new data.
#

#YOUR_IP=" "
#SOURCE="iplist.txt"
#ACCESS_LOG="/path/to/access.log"
IPCALC="/usr/bin/ipcalc"

if [ $EUID -ne "0" ]; then
   echo "Please run with sudo"
   exit 1
fi


Build_ip_list() {
PASS="<db-password>"
DBNAME="<db-name>"
DBUSER="<db-user>"
HOST="<db-host>"
DBTABLE="<db-table-with-comments>" 

GetIP() {
mysql -h ${HOST} -u${DBUSER} ${DBNAME} -p${PASS}  << EOF
select comment_author_IP,comment_approved from ${DBTABLE}
quit
EOF
}

IPLIST_ARRAY=( $(GetIP | sort -u | grep -v "comment" |perl -n -e'print if /\S/' |perl -lne '/spam/ and print' | perl -pale '$_="@F[0]"'| sort -u | sort -n) )
}

Get_Country() {
ip=$1
/usr/bin/whois -H $ip | perl -lne '/[Cc]ountry/ and print' | sort -u | perl -pale '$_="@F[1]"'
}

Get_CIDR() {
ip=$1
/usr/bin/whois -H $ip | perl -lne '/CIDR/ and print' | sort -u | awk -F" " '{print $2}'
}

Get_Range() {
ip=$1
/usr/bin/whois -H $ip | perl -lne '/inetnum/ and print' | sort -u | perl -pale '$_="@F[1,3]"'
}

Calculate_CIDR() {
range=$1
$IPCALC "$range" | perl -lne '/Network/ and print' | perl -pale '$_="@F[1]"'
}

Process() {
declare -a CHINA_RANGE_TMP_ARRAY
declare -a RUSSIA_RANGE_TMP_ARRAY
declare -a OTHER_RANGE_TMP_ARRAY

for ipaddress in ${IPLIST_ARRAY[*]}
   do
   CIDR=$(Get_CIDR ${ipaddress})
   COUNTRY=$(Get_Country ${ipaddress})
   RANGE=$(Get_Range ${ipaddress})
   RANGE_CIDR=$(Calculate_CIDR ${RANGE})
   CHECK_CIDR=$(Get_CIDR ${ipaddress} | wc -l)

AnalyzeCountry() {
PROVIDE_CIDR_BLOCK="$1"
if [ "$COUNTRY" == "CN" ]; then
	CHINA_RANGE_TMP_ARRAY=("${CHINA_RANGE_TMP_ARRAY[@]}" "${PROVIDE_CIDR_BLOCK}" )
elif [ "$COUNTRY" == "RU" ]; then
	RUSSIA_RANGE_TMP_ARRAY=("${RUSSIA_RANGE_TMP_ARRAY[@]}" "${PROVIDE_CIDR_BLOCK}" )
else
	OTHER_RANGES_TMP_ARRAY=("${OTHER_RANGES_TMP_ARRAY[@]}" "${PROVIDE_CIDR_BLOCK}" )
fi
}
	
if [ "${CHECK_CIDR}" -eq "0" ]; then
	# get range & check country then add to array based on country
	AnalyzeCountry "${RANGE_CIDR}"
elif [ "${CHECK_CIDR}" -eq "1" ]; then
	# check country & add to array based on country
	AnalyzeCountry "${CIDR}"
fi

done

# Sort values in arrays
CHINA_RANGE_SORTED=$( echo ${CHINA_RANGE_TMP_ARRAY[@]} | tr " " "\n" | sort -u) 
RUSSIA_RANGE_SORTED=$( echo ${RUSSIA_RANGE_TMP_ARRAY[@]} | tr " " "\n" | sort -u) 
OTHER_RANGE_SORTED=$( echo ${OTHER_RANGES_TMP_ARRAY[@]} | tr " " "\n" | sort -u) 

PrintChina() {
for cn in ${CHINA_RANGE_SORTED[@]}
do
	echo "Deny from $cn"
done
}
	
PrintRussia() {
for ru in ${RUSSIA_RANGE_SORTED[@]}
do
	echo "Deny from $ru"
done
}
	
PrintOther() {
for o in ${OTHER_RANGE_SORTED[@]}
do
	echo "Deny from $o"
done
}

echo -e "# Block CHINA sources\n$(PrintChina)"
echo -e "# Block RUSSIA sources\n$(PrintRussia)"
echo -e "# Block OTHER sources\n$(PrintOther)"
}

Build_ip_list
Process 
