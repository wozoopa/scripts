#!/bin/bash
#======================================================================================
# ===    Security Configuration Benchmark  for RedHat based systems    ===
#    based on version 2.0.0, Dec 16th 2011
#  
#  TODO:
#     - add main description
#    - add description to functions
#    - fix clean coding (ex:
#        ^VARIABLE_NAMES -> lower case
#        ^Function_Names -> upper case
#    - finish questions
#    - finish output formatting (not required)
#    - use perl where possible for better performance
#    - user arrays for better performance
#
#    NOTES:
# 1) AUDIT_ONLY MODE:
#     - This script checks if correct settings/parameters are set
#        and it does not fix them
#    - available modes: 0 - Audit only, 1 - Audit and try to Fix
#
#======================================================================================
set +o noclobber

AUDITMODE="0"

Begin_Security_Configuration_Benchmark() {
#=== Begin_Security_Configuration_Benchmark ==========================
#    
# DESCRIPTION: Container of all functions (etc.) for performing
#         Security Benchmark.
# PARAMETER: NONE
#=========================================

Check_User() {
#=== Check_User ==========================
#    
# DESCRIPTION: Make sure we're root
# PARAMETER: NONE
#=========================================

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or using sudo"
    exit 2
fi
}

Check_User

NAME=$(basename $0 .sh)
Date=$(date +%Y%m%d_%H%M)
LOG=" "
BKPDIR="$(pwd)/Benchmark_backup"
if [ ! -d $BKPDIR ]; then  mkdir $BKPDIR; else echo "exists" >>/dev/null; fi
TMPF="$(pwd)/etc-fstab.tmp"

#FSTAB="/etc/fstab"
#FSTAB="/home/ec2-user/work/benchmark-test/test-fstab"                # used for testing on Ec2
FSTAB="$(pwd)/etc-fstab.local"                                  # used for testing on Ec2 AMI Images
TMP="/tmp"
#TMP="/media/tmp"                                # used for testing on Ec2
VAR="/var"
#VAR="/media/var"                                # used for testing on Ec2
VARTMP="/var/tmp"
#VARTMP="/media/var/tmp"
VARLOG="/var/log"
#VARLOG="/media/var/log"
VARLOGAUDIT="/var/log/audit"
#VARLOGAUDIT="/media/var/log/audit"
HOME="/home"
#HOME="/media/home"
GRUB="/etc/grub.conf"

echo "Creating temporary working file ${FSTAB}"
cp /etc/fstab ${FSTAB}

fstabName=$( echo $FSTAB | sed 's/\//\t/g' | awk '{print $NF}')
CheckTmpMount=$(mount | grep "$TMP" |grep -v "log\|bind\|var\|tmpfs" | wc -l)
CheckTmpFstab=$(grep "$TMP" $FSTAB | grep -v "log\|bind\|var\|tmpfs" | wc -l)
CheckVarMount=$(mount | grep "$VAR" | grep -v "log\|tmp\|bind\|audit" | wc -l)
CheckVarFstab=$(grep "$VAR" $FSTAB | grep -v "log\|tmp\|bind\|audit" | wc -l)
CheckVarTmpMount=$(mount | grep "$VARTMP" | wc -l)
CheckVarTmpFstab=$(grep "$VARTMP" $FSTAB | wc -l)
CheckVarLogMount=$(mount | grep "$VARLOG" | grep -v "tmp\|bind\|audit" | wc -l)
CheckVarLogFstab=$(grep "$VARLOG" $FSTAB | grep -v "tmp\|bind\|audit" | wc -l)
CheckVarLogAuditMount=$(mount | grep "$VARLOGAUDIT" | wc -l)
CheckVarLogAuditFstab=$(grep "$VARLOGAUDIT" $FSTAB | wc -l)
CheckHomeMount=$(mount | grep $HOME | wc -l)
CheckHomeFstab=$(grep "$HOME" $FSTAB | grep -v "log\|tmp\|bind\|audit" | wc -l)
CheckHomeNodevFstab=$(grep "$HOME" $FSTAB | grep "nodev" | wc -l)
CheckHomeNodevMount=$(mount | grep "$HOME" | grep "nodev" | wc -l)
RemovableMedia=$(mount | grep "/media" | awk -F"on" '{print $2}' | awk -F" " '{print $1}' | sed ':a;N;$!ba;s/\n/ /g')
RemovableMediaCount=$(mount | grep "/media" | awk -F"on" '{print $2}' | awk -F" " '{print $1}' | wc -l)
#CheckRemovableMediaNodevMount=$(mount | grep "${i}" | grep "nodev" | wc -l) # $1
#CheckRemovableMediaNodevmFstab$(grep "/media" $FSTAB | )
RemovableMediaFstab=$(grep "/media" $FSTAB | awk -F" " '{print $2}' | sed ':a;N;$!ba;s/\n/ /g')
RemovableMediaFstabCount=$(grep "/media" $FSTAB | awk -F" " '{print $2}' | wc -l)
DevShmNodevMountCount=$(mount | grep "/dev/shm" | grep "nodev" | wc -l)
DevShmNodevFstabCount=$(grep "/dev/shm" $FSTAB | grep "nodev" | wc -l)
DevShmNosuidMountCount=$(mount | grep "/dev/shm" | grep "nosuid" | wc -l)
DevShmNosuidFstabCount=$(grep "/dev/shm" $FSTAB | grep "nosuid" | wc -l)
DevShmNoexecMountCount=$(mount | grep "/dev/shm" | grep "nosuid" | wc -l)
DevShmNoexecFstabCount=$(grep "/dev/shm" $FSTAB | grep "nosuid" | wc -l)

CheckFstabNodev=$(grep "$TMP" $FSTAB | grep "nodev" | wc -l)
CheckTmpNodev=$(mount | grep "$TMP" | grep nodev | wc -l)
CheckFstabNosuid=$(grep "$TMP" $FSTAB | grep "nosuid" | wc -l)
CheckTmpNosuid=$(mount | grep $TMP | grep nosuid | wc -l)
CheckFstabNoexec=$(grep "$TMP" $FSTAB | grep "noexec" | wc -l)
CheckTmpNoexec=$(mount | grep $TMP | grep "noexec" | wc -l)

CheckMountPoint() {
#==== CheckMountPoint =======================================================
#
# test given mount point for selected parameter
# $1 = mount point, ex: /dev/shm
# $2 = parameter, ex: nodev
#============================================================================

Usg() {
echo "Please provide 2 arguments to CheckMountPoint function"
}

(( $# != 2 )) && Usg

mount | grep "$1" | grep "$2" | wc -l
}

err() {
#==== err =======================================================
#
# Display Error message with nice formatting, in red color
#
# usg: err "<count_of_tabs>" "<Message>"
#============================================================================

printf_new() {
 str=$1
 num=$2
 v=$(printf "%-${num}s" "$str")
 echo "${v// /\t}"
}
echo -e "$(printf_new "\t" $1) ..................... \033[1;31m ERROR: $2 \033[m"
}

skipNoticeA() {
echo -e "\033[1;36m  ..................................................................................... NOTICE: $1 \n \033[m"
}

skipNotice() {
echo -e "\033[1;36m \t \t \t \t \t \t \t \t \t ..................... NOTICE: Skipping parameter checks for $1 mount point. \033[m" # just add mount point
}

skipMountCheck() {
echo -e "\033[1;36m \t \t \t \t \t \t \t \t \t ..................... NOTICE: Skipping parameter checks for $1 mount point. \033[m" # just add mount point
}

Notice() {
#==== Notice =======================================================
#
# Display Notice message with nice formatting
#
# usage: Notice "<count_of_tabs>" "<Message>"
#===================================================================
printf_new() {
 str=$1
 num=$2
 v=$(printf "%-${num}s" "$str")
 echo "${v// /\t}"
}
echo -e "$(printf_new "\t" $1) ..................... \033[1;36m $2 \033[m"
}

Notice2() {
#==== Notice2 =======================================================
#
# Display Notice message with nice formatting
#
# usage: Notice2 "<count_of_tabs>" "<Message>"
#====================================================================

printf_new() {
 str=$1
 num=$2
 v=$(printf "%-${num}s" "$str")
 echo "${v// /\t}"
}
echo -e "$(printf_new "\t" $1)  \033[1;36m $2 \033[m"
}

ENB() {
    echo -e "\033[1;36m ENABLED \033[m"
}

DIS() {
    echo -e "\033[1;36m DISABLED \033[m"
}

warn() {
#==== warn =======================================================
#
# Display Warning message with nice formatting, in red color
#
# usage: warn "<count_of_tabs>" "<Message>"
#=================================================================

printf_new() {
 str=$1
 num=$2
 v=$(printf "%-${num}s" "$str")
 echo "${v// /\t}"
}
echo -e "\n $(printf_new "\t" $1) ..................... \033[1;31m WARNING: $2 \033[m"
}

OK() {
#==== OK =======================================================
#
# Display OK message with nice formatting
#
# usage: OK "<count_of_tabs>" "<Message>"
#=================================================================

printf_new() {
 str=$1
 num=$2
 v=$(printf "%-${num}s" "$str")
 echo "${v// /\t}"
}
echo -e "$(printf_new "\t" $1) ..................... OK"
}

CheckupErr() {
echo -e "\033[1;31mWARNING: something went wrong $1. \033[m"
}

# echo  -e "\033[1;36m....................Change requires reboot. \033[m"

VarMountErr() {
echo -e "\033[1;31mWARNING: $VAR NOT MOUNTED ON SEPARATE PARTITION !!! \033[m"
echo  -e "\033[1;36m...............Change requires reboot. \033[m"
}

VarTmpMountErr() {
echo -e "\033[1;31mWARNING: $VARTMP NOT binded to $TMP !!! \033[m"
}

VarLogMountErr() {
echo -e "\033[1;31mWARNING: $VARLOG NOT MOUNTED ON SEPARATE PARTITION !!! \033[m"
echo  -e "\033[1;36m................Change requires reboot. \033[m"
}

################################################
## Checks againts $TMP mount point
################################################

remountNodev() {
echo "............................ Remounting $1 with nodev parameter"
sudo mount -o remount,nodev $1

}

FixTmpNodev() { # replace this function in the script with remountNodev $TMP
echo "Remounting $TMP with nodev parameter"
sudo mount -o remount,nodev $TMP
}

#TmpNosuidWarn() {
#echo -e "\033[1;31mWARNING: NOT mounted with nosuid \033[m"
#}

FixTmpNosuid() {
echo "Remounting $TMP with nosuid parameter"
sudo mount -o remount,nodev,nosuid $TMP
}

#TmpNoexecWarn() {
#echo -e "\033[1;31mWARNING: NOT mounted with noexec \033[m"
#}

FixTmpNoexec() {
echo "Remounting $TMP with noexec parameter"
sudo mount -o remount,nodev,nosuid,noexec $TMP
}

TmpCheck() {

        echo -n "1.1.2a - Checking mounted $TMP for nodev "
        if [ "$CheckTmpNodev" = "0" ]; then
                warn "11" "NOT mounted with nodev"
        elif [ "$CheckTmpNodev" = "1" ]; then
                OK "6"
        else
                CheckupErr
        fi

        echo -n "1.1.3a - Checking mounted $TMP for nosuid "
        if [ "$CheckTmpNosuid" = "0" ]; then
                #TmpNosuidWarn
                warn "11" "NOT mounted with nosuid"
        elif [ "$CheckTmpNosuid" = "1" ]; then
                OK "6"
        else
                CheckupErr
        fi

        echo -n "1.1.4a - Checking mounted $TMP for noexec "
        if [ "$CheckTmpNoexec" = "0" ]; then
                #TmpNoexecWarn
                warn "11" "NOT mounted with noexec"
        elif [ "$CheckTmpNoexec" = "1" ]; then
                OK "6"
        else
                CheckupErr
        fi
}

TmpCheckFix() {

        echo -n "1.1.2b - Checking mounted $TMP for nodev "
        if [ "$CheckTmpNodev" = "0" ]; then
                warn "11" "NOT mounted with nodev"
                FixTmpNodev
        elif [ "$CheckTmpNodev" = "1" ]; then
                OK "6"
        else
                CheckupErr
        fi

        echo -n "1.1.3b - Checking mounted $TMP for nosuid "
        if [ "$CheckTmpNosuid" = "0" ]; then
                #TmpNosuidWarn
                warn "11" "NOT mounted with nosuid"
                FixTmpNosuid
        elif [ "$CheckTmpNosuid" = "1" ]; then
                OK "5"
        else
            CheckupErr
        fi

        echo -n "1.1.4b - Checking mounted $TMP for noexec "
        if [ "$CheckTmpNoexec" = "0" ]; then
                #TmpNoexecWarn
                warn "11" "NOT mounted with noexec"
                FixTmpNoexec
        elif [ "$CheckTmpNoexec" = "1" ]; then
                OK "5"
        else
                CheckupErr
        fi
}

################################################
## Checks againts /etc/fstab file
################################################

FixFstabNodev() {
echo "Adding nodev parameter to fstab working file."
replaceCol1=$(cat $FSTAB | grep "$TMP" | awk -F" " '{print $4}')
cp $FSTAB $BKPDIR/$fstabName.${Date}_bkp
grep -v "$TMP" $FSTAB >>${TMPF}
cat $FSTAB | grep "$TMP" | sed "s/${replaceCol1}/${replaceCol1},nodev/" >>${TMPF}
}

FixFstabNosuid() {
echo "Adding nosuid parameter to fstab working file."
replaceCol2=$(cat $TMPF | grep "$TMP" | awk -F" " '{print $4}')
grep -v "$TMP" $TMPF >>${TMPF}.nosuid
grep "$TMP" $TMPF | sed "s/${replaceCol2}/${replaceCol2},nosuid/" >>$TMPF.nosuid
#rm -rf $TMPF
}

FixFstabNoexec() {
echo "Adding noexec parameter to fstab working file."
replaceCol2=$(cat ${TMPF}.nosuid | grep "$TMP" | awk -F" " '{print $4}')
grep -v "$TMP" ${TMPF}.nosuid >>${TMPF}.noexec
grep "$TMP" ${TMPF}.nosuid | sed "s/${replaceCol2}/${replaceCol2},noexec/" >>${TMPF}.noexec
cp ${TMPF}.noexec ${TMPF}
}

FstabTmpCheck() {

    echo -n "1.1.1b - Checking $fstabName for $TMP "
if [ "$CheckTmpFstab" = "0" ]; then
            #FstabNoTmpErr
                    
            err "6" " $TMP missing from $fstabName"
            skipNotice "Skipping parameter checks for $TMP in $fstabName file."

elif [ "$CheckTmpFstab" = "1" ]; then
            OK "6"

        echo -n "1.1.2b - Checking $fstabName for nodev on $TMP "
        if [ "$CheckFstabNodev" = "0" ]; then
                #FstabNodevWarn
                warn "11" "nodev parameter missing from $fstabName"
        elif [ "$CheckFstabNodev" = "1" ]; then
                OK "5"
        else
                CheckupErr
        fi

        echo -n "1.1.3b - Checking $fstabName for nosuid on $TMP "
        if [ "$CheckFstabNosuid" = "0" ]; then
                warn "11" "nosuid parameter missing from $fstabName"
        elif [ "$CheckFstabNosuid" = "1" ]; then
                OK "5"
        else
                CheckupErr
        fi

        echo -n "1.1.4b - Checking $fstabName for noexec on $TMP "
        if [ "$CheckFstabNoexec" = "0" ]; then
                warn "11" "noexec parameter missing from $fstabName"
        elif [ "$CheckFstabNoexec" = "1" ]; then
                OK "5"
        else
                CheckupErr
        fi

else
    CheckupErr
fi
}

FstabTmpCheckFix() {

    echo -n "1.1.1b - Checking $fstabName for $TMP "
if [ "$CheckTmpFstab" = "0" ]; then                # /tmp doesn't exist in fstab file

            grep -v "$TMP" $FSTAB >>${TMPF}
                        if [ "$CheckTmpMount" = "0" ]; then
                                echo -e "\033[1;31mWARNING: Unable to update $fstabName because $TMP is NOT mounted on separate partition!  \033[m"
                        elif [ "$CheckTmpMount" = "1" ]; then
                            OK "6"
                            echo "............ Updating fstab with the following line: "
TMPMOUNTPOINT=$(mount | grep "/tmp" |grep -v "/var\|log\|bind" | awk -F" " '{print $1,$3,$5}')
                            echo -e " $TMPMOUNTPOINT \t defaults \t 0 \t 2"
                            echo -e " $TMPMOUNTPOINT \t defaults \t 0 \t 2" >>${TMPF}
                        else
                            CheckupErr
                        fi

elif [ "$CheckTmpFstab" = "1" ]  && [ "$CheckTmpMount" = "1" ];  then # /tmp exists in fstab file and is mounted on separate partition
    OK "6"
        echo -n "1.1.2b - Checking $fstabName for nodev on $TMP "
        if [ "$CheckFstabNodev" = "0" ]; then
                warn "11" "nodev parameter missing from $fstabName"
                FixFstabNodev
        elif [ "$CheckFstabNodev" = "1" ]; then
                OK "6"
        else
                CheckupErr
        fi

        echo -n "1.1.3b - Checking $fstabName for nosuid on $TMP "
        if [ "$CheckFstabNosuid" = "0" ]; then
                warn "11" "nosuid parameter missing from $fstabName"
                FixFstabNosuid
        elif [ "$CheckFstabNosuid" = "1" ]; then
                OK "5"
        else
                CheckupErr
        fi

        echo -n "1.1.4b - Checking $fstabName for noexec on $TMP "
        if [ "$CheckFstabNoexec" = "0" ]; then
                warn "11" "noexec parameter missing from $fstabName"
                FixFstabNoexec
        elif [ "$CheckFstabNoexec" = "1" ]; then
                OK "3"
        else
                CheckupErr
        fi

elif [ "$CheckTmpFstab" = "1" ]  && [ "$CheckTmpMount" = "0" ];  then # /tmp exists in fstab file but is NOT mounted on separate partition
    warn "11" " $TMP exists in $fstabName but is NOT mounted."
    echo "............................................. Please fix that manually."

else                                                                # elif "$CheckTmpFstab" = "1"
    CheckupErr
fi
}

CheckVar() {
echo -n "1.1.5a - Checking if $VAR is on separate partition "
if [ "$CheckVarMount" = "0" ]; then
                            warn "11" "$VAR NOT MOUNTED ON SEPARATE PARTITION !!!"
                            skipNoticeA "...............Change requires reboot."
                            grep -v "$VAR" $FSTAB >>${TMPF}
                            cat ${TMPF} | sort -u >> ${TMPF}.sorted
                            mv ${TMPF}.sorted ${TMPF}
elif [ "$CheckVarMount" = "1" ]; then
                            OK "5"
else
    CheckupErr
fi
}

CheckVarFix() {
echo -n "1.1.5a - Checking if $VAR is on separate partition "
if [ "$CheckVarMount" = "0" ]; then
                            warn "11" "$VAR NOT MOUNTED ON SEPARATE PARTITION !!!"
                            skipNoticeA "...............Change requires reboot."
                            echo " ............... Please mount $VAR partition manually !!"
                            echo -e "............... \033[1;36mChange requires reboot. \033[m"
elif [ "$CheckVarMount" = "1" ]; then
                            OK "5"
else
    CheckupErr
fi
}

FstabVarCheck() {
echo -n "1.1.5b - Checking $fstabName for $VAR "
if [ "$CheckVarFstab" = "0" ]; then
    err "6" "$VAR missing from $fstabName"
elif [ "$CheckVarFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

FstabVarCheckFix() {
echo -n "1.1.5b - Checking $fstabName for $VAR "
if [ "$CheckVarFstab" = "0" ]; then
    err "6" "$VAR missing from $fstabName"
            if [ "$CheckVarMount" = "0" ]; then
                echo " ............... Unable to fix $fstabName file because $VAR is not mounted on separate partition."
            else
    echo -e "\033[1;31m ............... Adding the following line to temporary working file:\033[m"
VARMOUNT=$(mount | grep $VAR | grep -v "bind\|log\|tmp" | awk -F" " '{print $1,$3,$5}')
    echo -e "\033[1;36m ............... $VARMOUNT \t 0 \t 2 \033[m"
    echo -e "$VARMOUNT \t 0 \t 2" >>${TMPF}
            fi
elif [ "$CheckVarFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

CheckVarTmp() { # /var/tmp
echo -n "1.1.6a - Checking if $VARTMP is binded to $TMP "
if [ "$CheckVarTmpMount" = "0" ]; then
                            warn "11"  " NOT binded to $TMP !!! "
elif [ "$CheckVarTmpMount" = "1" ]; then
                            OK "5"
else
    CheckupErr
fi
}

CheckVarTmpFix() {

echo -n "1.1.6a - Checking if $VARTMP is binded with $TMP "
if [ "$CheckVarTmpMount" = "0" ]; then
                            warn "11"  " NOT binded to $TMP !!! "
                            #check if /tmp is on separate partition, if yes then we can bind with it
                                if [ "$CheckTmpMount" = "0" ]; then
                                    echo " ................ Unable to bind $VARTMP with $TMP because $TMP is not on separate partition"
                                elif [ "$CheckTmpMount" = "1" ]; then
                            echo -e " ................. \033[1;36m Binding $VARTMP with $TMP \033[m"
                            mount --bind $TMP $VARTMP
                                else
                                    CheckupErr
                                fi
elif [ "$CheckVarTmpMount" = "1" ]; then
                            OK "5"
else
    CheckupErr
fi
}

FstabVarTmpCheck() {
echo -n "1.1.6b - Checking $fstabName for $VARTMP "
if [ "$CheckVarTmpFstab" = "0" ]; then
    warn "11"  "missing from $fstabName "
elif [ "$CheckVarTmpFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

FstabVarTmpCheckFix() {
echo -n "1.1.6b - Checking $fstabName for $VARTMP "
if [ "$CheckVarTmpFstab" = "0" ]; then
    warn "11"  "missing from $fstabName "
            # check if var/tmp is binded, if yes then add line to TMPF, if no then display error message
            echo -n "1.1.6a - Checking if $VARTMP is binded to $TMP "
                if [ "$CheckVarTmpMount" = "0" ]; then
                            warn "11" "NOT binded to $TMP !!! "
                elif [ "$CheckVarTmpMount" = "1" ]; then
                            OK "3"
                    echo -e " ............... Adding following line to $TMPF:"
                    VARTMPMOUNT=$(mount | grep $VARTMP | awk -F" " '{print $1,$3}')
                    echo -e "${VARTMPMOUNT} \t none \t none \t 0 \t 0 " >>${TMPF}
                else
                        CheckupErr
                fi
elif [ "$CheckVarTmpFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

CheckVarLog() { # /var/log
echo -n "1.1.7b - Checking if $VARLOG is on separate partition "
if [ "$CheckVarLogMount" = "0" ]; then
    warn "11"  "$VARLOG NOT MOUNTED ON SEPARATE PARTITION !!!"
    skipNoticeA "Change requires reboot."
elif [ "$CheckVarLogMount" = "1" ]; then
    OK "5"
    FstabVarlogCheck
else
    CheckupErr
fi
}

CheckVarLogFix() {
echo -n "1.1.7b - Checking if $VARLOG is on separate partition "
if [ "$CheckVarLogMount" = "0" ]; then
    warn "11"  "$VARLOG NOT MOUNTED ON SEPARATE PARTITION !!!"
    skipNoticeA "............... Please mount $VARLOG partition manually and add the following line to $fstabName:"
    skipNoticeA "............... \033[1;36m <volume> \t $VARLOG \t ext3 \t <options>"
elif [ "$CheckVarLogMount" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

FstabVarlogCheck() {
echo -n "1.1.7a - Checking  $fstabName for $VARLOG "
if [ "$CheckVarLogFstab" = "0" ]; then
    err "5" "$VARLOG missing from $fstabName."
elif [ "$CheckVarLogFstab" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

FstabVarLogCheckFix() {
echo -n "1.1.7a - Checking  $fstabName for $VARLOG "
grep -v "$TMP" $FSTAB >>${TMPF}

if [ "$CheckVarLogFstab" = "0" ]; then
    err "5" "$VARLOG missing from $fstabName."
            if [ "$CheckVarLogMount" = "1" ]; then
    echo " ............... Adding following line to to temporary working file:"
VARLOGMOUNT=$(mount | grep "$VARLOG" | grep -v "audit\|tmp\|bind" | awk -F" " '{print $1,$3,$5}')
    echo -e " ............... $VARLOGMOUNT \t 0 \t 2"
    echo -e "${VARLOGMOUNT} \t 0 \t 2 " >>${TMPF}
    #cat ${TMPF}.noexec | sort -u >> ${TMPF}.noexec.sorted
    #mv ${TMPF}.noexec.sorted ${TMPF}.noexec

            elif [ "$CheckVarLogMount" = "0" ]; then
                warn "11" "Unable to update $fstabName because $VARLOG is not mounted on separate partition."
            else
                CheckupErr
            fi
elif [ "$CheckVarLogFstab" = "1" ]; then
        OK "5"
else
        CheckupErr
fi
}

FstabVarLogAuditCheck() { # /var/log/audit
echo -n "1.1.8a - Checking  $fstabName for $VARLOGAUDIT "
if [ "$CheckVarLogAuditFstab" = "0" ]; then
    warn "11"  "$VARLOGAUDIT missing from $fstabName."
elif [ "$CheckVarLogAuditFstab" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

FstabVarLogAuditCheckFix() {
echo -n "1.1.8a - Checking  $fstabName for $VARLOGAUDIT "
if [ "$CheckVarLogAuditFstab" = "0" ]; then
    warn "11"  "$VARLOGAUDIT missing from $fstabName."
            if [ "$CheckVarLogAuditMount" = "0" ]; then
                echo -e "\033[1;31mWARNING: Unable to update $fstabName because $VARLOGAUDIT is NOT mounted on separate partition!  \033[m"
            elif [ "$CheckVarLogAuditMount" = "1" ]; then
                echo " ............... Adding following line to to temporary working file:"
VARLOGAUDITMOUNT=$(mount | grep "$VARLOGAUDIT"| awk -F" " '{print $1,$3,$5}')
                echo -e " ............... $VARLOGAUDITMOUNT \t 0 \t 2"
                echo -e "$VARLOGAUDITMOUNT \t 0 \t 2" >>${TMPF}
            else
                CheckupErr
            fi
elif [ "$CheckVarLogAuditFstab" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

CheckVarLogAudit() {
echo -n "1.1.8b - Checking if $VARLOGAUDIT is on separate partition "
if [ "$CheckVarLogAuditMount" = "0" ]; then
    warn "11" "WARNING: $VARLOGAUDIT NOT MOUNTED ON SEPARATE PARTITION"
elif [ "$CheckVarLogAuditMount" = "1" ]; then
    OK "4"
else
    CheckupErr
fi
}

CheckVarLogAuditFix() {
echo -n "1.1.8b - Checking if $VARLOGAUDIT is on separate partition "
if [ "$CheckVarLogAuditMount" = "0" ]; then
    warn "11" "WARNING: $VARLOGAUDIT NOT MOUNTED ON SEPARATE PARTITION"
    echo  -e "\033[1;36m................Change requires reboot. \033[m"
    echo " ................ Please mount $VARLOGAUDIT partition manually and add the following line to $fstabName:"
    echo -e " ............... \033[1;36m <volume> \t $VARLOGAUDIT \t ext3 \t <options> \033[m"
elif [ "$CheckVarLogAuditMount" = "1" ]; then
    OK "4"
else
    CheckupErr
fi
}

CheckHome() { # /home
echo -n "1.1.9a - Checking if $HOME is on separate partition"
if [ "$CheckHomeMount" = "0" ]; then
    warn "11" "$HOME NOT MOUNTED ON SEPARATE PARTITION"
elif [ "$CheckHomeMount" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

CheckHomeFix() {
echo -n "1.1.9a - Checking if $HOME is on separate partition "
if [ "$CheckHomeMount" = "0" ]; then
    warn "11" "$HOME NOT MOUNTED ON SEPARATE PARTITION !"
    echo -e ".................................... Please mount $HOME partition manually with nodev parameter"
    echo -e ".................................... Please add new mount to $fstabName file."
elif [ "$CheckHomeMount" = "1" ]; then
    OK "5"
else
    CheckupErr
fi
}

FstabHomeCheck() {
echo -n "1.1.9b - Checking  $fstabName for $HOME "
if [ "$CheckHomeFstab" = "0" ]; then
    warn "11" "$HOME missing from $fstabName."
elif [ "$CheckHomeFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

FstabHomeFix() {
echo -n "1.1.9b - Checking  $fstabName for $HOME "
if [ "$CheckHomeFstab" = "0" ]; then
    warn "11" "$HOME missing from $fstabName."
            if [ "$CheckHomeMount" = "1" ]; then
HOMEMOUNTPOINT=$(mount | grep "/home" | awk -F" " '{print $1,$3,$5}')
                skipNoticeA "Adding the following line to $fstabName"
                echo -e " $HOMEMOUNTPOINT \t defaults \t 0 \t 2"
                echo -e " $HOMEMOUNTPOINT \t defaults \t 0 \t 2" >>${TMPF}
            elif [ "$CheckHomeMount" = "0" ]; then
                err "3" "Unable to update $fstabName file because $HOME is not mounted on separate partition!"
                echo -e ".............................. Please mount $HOME on new partition manually and then update $fstabName file."
            else
                CheckupErr
            fi
elif [ "$CheckHomeFstab" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

checkHomeNodev() { # /home nodev check
echo -n "1.1.10a - Checking mounted $HOME for nodev "
if [ "$CheckHomeNodevMount" = "0" ]; then
    warn "11" "NOT mounted with nodev"
elif [ "$CheckHomeNodevMount" = "1" ]; then
    OK "6"
else
    CheckupErr
fi
}

checkHomeNodevFix() {
echo -n "1.1.10a - Checking mounted $HOME for nodev "
 if [ "$CheckHomeNodevMount" = "0" ]; then
    warn "11" "NOT mounted with nodev"
    echo -e "................... Remounting partition."
    remountNodev ${HOME}
 elif [ "$CheckHomeNodevMount" = "1" ]; then
    OK "6"
 else
    CheckupErr
fi
}

fstabHomeNodevCheck() {
echo -n "1.1.10 - Checking $fstabName for nodev on $HOME "
 if [ "$CheckHomeNodevFstab" = "0" ]; then
    warn "11" "parameter missing."
 elif [ "$CheckHomeNodevFstab" = "1" ]; then
    OK "5"
 else
    CheckupErr
 fi
}

fstabHomeNodevFix() {
echo "nothing yet" >> /dev/null
}

# nodev on Removable Media
# Assume that all removable media are mounted on /media/...
CheckNodevRemMediaMount() {
 for i in ${RemovableMedia}
  do
echo -n "1.1.11a - Checking $i (removable media) for nodev  "
    RemovableMediaNodevCount=$(mount | grep "${i}" | grep "nodev" | wc -l)
        if [ "$RemovableMediaNodevCount" = "0" ]; then
            warn "11" "$i NOT mounted with nodev"
        elif [ "$RemovableMediaNodevCount" = "1" ]; then
            OK "3"
        else
            CheckupErr "nodev"
            echo "RemovableMediaNodevCount is $RemovableMediaNodevCount"
        fi
done
}

CheckNodevRemMediaMountFix() {
echo "nothing yet" >>/dev/null
}

CheckNodevRemMediaFstab() {
 for i in ${RemovableMediaFstab}
  do
echo -n "1.1.11b - Checking  $fstabName for nodev parameter on removable media ( ${i} )"
        RemovableMediaFromFstabIfMounted=$(mount | grep "${i}" | wc -l)
                if [ "$RemovableMediaFromFstabIfMounted" = "0" ]; then
                        warn "11" "NOT mounted but exists in $fstabName."
                # if yes then check if media has nodev parameter in fstab file:
                elif [ "$RemovableMediaFromFstabIfMounted" = "1" ]; then
RemovableMediaNodevFstabCheck=$( grep "${i}" $FSTAB | grep "nodev" | wc -l)
                                        if [ "$RemovableMediaNodevFstabCheck" = "0" ]; then
                                                warn "11" "parameter missing."
                                        elif [ "$RemovableMediaNodevFstabCheck" = "1" ]; then
                                                OK "3"
                                        else
                                                CheckupErr "checking parameter for $i in fstab"
                                        fi
                else
                        CheckupErr "with check if $i is mounted"
                fi
  done
}

CheckNodevRemMediaFstabFix() {
echo "nothing yet" >>/dev/null
}

# noexec on Removable Media
# Assume that all removable media are mounted on /media/...
CheckNoexecRemMediaMount() {
 for i in ${RemovableMedia}
  do
echo -n "1.1.12a - Checking $i (removable media) for noexec  "
    RemovableMediaNoexecCount=$(mount | grep "${i}" | grep "noexec" | wc -l)
        if [ "$RemovableMediaNoexecCount" = "0" ]; then
            warn "11" "$i NOT mounted with noexec"
        elif [ "$RemovableMediaNoexecCount" = "1" ]; then
            OK "3"
        else
            CheckupErr "$i is mounted with noexec"
        fi
 done
}

CheckNoexecRemMediaMountfix() {
echo "nothing yet" >>/dev/null
}

CheckNoexecRemMediaFstab() {
 for i in ${RemovableMediaFstab}
  do
echo -n "1.1.12a - Checking  $fstabName for noexec parameter on removable media ( ${i} ) "
        RemovableMediaFromFstabIfMounted=$(mount | grep "${i}" | wc -l)
                if [ "$RemovableMediaFromFstabIfMounted" = "0" ]; then
                        warn "11" "NOT mounted but exists in $fstabName."
                elif [ "$RemovableMediaFromFstabIfMounted" = "1" ]; then
RemovableMediaNoexecFstabCheck=$( grep "${i}" $FSTAB | grep "noexec" | wc -l)
                                        if [ "$RemovableMediaNoexecFstabCheck" = "0" ]; then
                                                warn "11" "parameter missing."
                                        elif [ "$RemovableMediaNoexecFstabCheck" = "1" ]; then
                                                OK "3"
                                        else
                                                CheckupErr "with check for $i in fstab for noexec"
                                        fi
                else
                        CheckupErr "with check if $i is mounted"
                fi
  done
}

CheckNoexecRemMediaFstabFix() {
echo "nothing yet" >>/dev/null
}

# nosuid on Removable Media
# Assume that all removable media are mounted on /media/...
CheckNosuidRemMediaMount() {
 for i in ${RemovableMedia}
  do
echo -n "1.1.13a - Checking $i (removable media) for nosuid  "
    RemovableMedianosuidCount=$(mount | grep "${i}" | grep "nosuid" | wc -l)
        if [ "$RemovableMedianosuidCount" = "0" ]; then
            warn "11" "NOT mounted with nosuid"
        elif [ "$RemovableMedianosuidCount" = "1" ]; then
            OK "3"
        else
            CheckupErr "with check if $i is mounted with nosuid"
        fi
done
}

CheckNosuidRemMediaMountFix() {
    echo "nothing yet" >>/dev/null
}

CheckNosuidRemMediaFstab() {
 for i in ${RemovableMediaFstab}
  do
echo -n "1.1.13a - Checking  $fstabName for nosuid parameter on removable media ( ${i} )"
        RemovableMediaFromFstabIfMounted=$(mount | grep "${i}" | wc -l)
                if [ "$RemovableMediaFromFstabIfMounted" = "0" ]; then
                        warn "11" "NOT mounted but exists in $fstabName."
                # if yes then check if media has nosuid parameter in fstab file:
                elif [ "$RemovableMediaFromFstabIfMounted" = "1" ]; then
RemovableMedianosuidFstabCheck=$( grep "${i}" $FSTAB | grep "nosuid" | wc -l)
                                        if [ "$RemovableMedianosuidFstabCheck" = "0" ]; then
                                                warn "11" "parameter missing."
                                        elif [ "$RemovableMedianosuidFstabCheck" = "1" ]; then
                                                OK "3"
                                        else
                                                CheckupErr "with check if $i has nosuid in fstab"
                                        fi
                else
                        CheckupErr "with check if $i is mounted"
                fi
 done
}

CheckNosuidRemMediaFstabFix() {
    echo "nothing yet" >>/dev/null
}

CheckMountedMediaInFstab() {
 for i in ${RemovableMedia}
   do
CountRemMediaMountedInFstab=$(grep "${i}" $FSTAB | wc -l)
        if [ "$CountRemMediaMountedInFstab" = "0" ]; then
            warn "11" "mounted but does NOT exists in $fstabName"
        elif [ "$CountRemMediaMountedInFstab" = "1" ]; then
            echo "OK" >>/dev/null
        else
            CheckupErr "with check if $i is in fstab"
        fi
  done
}

CheckRemovableMediaMount() {
echo -n "1.1.11aa - Checking for attached removable devices "
if [ "$RemovableMediaCount" = "0" ]; then
     warn "11"  "no removable devices mounted on the system."
     Notice2 "1" "NOTICE: Skipping parameter checks for removable mount point."
else
        CheckMountedMediaInFstab
        CheckNodevRemMediaMount
        CheckNoexecRemMediaMount
        CheckNosuidRemMediaMount
fi
}

CheckRemovableMediaFstab() {
echo -n "1.1.11ab - Checking for removable devices in fstab file"
if [ "$RemovableMediaFstabCount" = "0" ]; then
        warn "11"  "no removable media found"
        #skipMountCheck "removable media in fstab file"
        Notice2 "1" "Skipping parameter checks for removable media in fstab file mount point."
else
    for i in ${RemovableMediaFstab}
     do
RemovableMediaFromFstabMountedCount=$( mount | grep -i "$i" | awk -F" " '{print $3}' | wc -l)
        if [ "$RemovableMediaFromFstabMountedCount" = "0" ]; then
            warn "11"  "NOT mounted but exists in $fstabName."
            Notice2 "1" "NOTICE: Skipping parameter checks for removable media in fstab file mount point."
        elif [ "$RemovableMediaFromFstabMountedCount" = "1" ]; then
            CheckNodevRemMediaFstab
            CheckNoexecRemMediaFstab
            CheckNosuidRemMediaFstab
        else
               echo "something wrong happened with check2"
        fi
     done
fi
}

RemMediaMsg() {
    echo -e "\033[1;36m Please note that you may have other removable media that is not detected by this script. \033[m"
    echo -e "\033[1;36m Please check these devices manually for nosuid,noexec or nodev parameters with this command: \033[m"
    echo -e "\033[1;36m sudo mount | grep <media_mount_point> \n \033[m"
}

# check nodev on /dev/shm
##
CheckNodevDevShmMount() {
mpoint="/dev/shm"
echo -n "1.1.14a - Checking $mpoint for nodev"
        if [ "$DevShmNodevMountCount" = "0" ]; then
            warn "11"  "NOT mounted with nodev"
        elif [ "$DevShmNodevMountCount" = "1" ]; then
           OK "7"
        else
            CheckupErr "with check if $i is mounted with nodev"
        fi
}

CheckNodevShmMountFix() {
    echo "nothing yet" >>/dev/null
}

CheckNodevDevShmFstab() {
mpoint="/dev/shm"
echo -n "1.1.14b - Checking  $fstabName for nodev parameter on $mpoint "
DevShmIfMounted=$(mount | grep "$mpoint" | wc -l)

if [ "$DevShmNodevFstabCount" = "1" ]; then
    if [ "$DevShmIfMounted" = "0" ]; then
        warn "11" "NOT mounted but exists in $fstabName."
    elif [ "$DevShmIfMounted" = "1" ]; then
        OK "4"
    else
        CheckupErr "with check if $mpoint is mounted since it exists in $FSTAB."
    fi
elif [ "$DevShmNodevFstabCount" = "0" ]; then
        warn "11" "parameter missing."
else
        CheckupErr "with check if parameter exists in $fstabName for $mpoint."
fi
}

CheckNodevShmFstabFix() {
echo "nothing yet" >>/dev/null
}

# Nosuid on /dev/shm
##

CheckNosuidDevShmMount() {
mpoint="/dev/shm"
echo -n "1.1.15a - Checking $mpoint for nosuid  "

        if [ "$DevShmNosuidMountCount" = "0" ]; then
            warn "11"  "NOT mounted with nosuid"
        elif [ "$DevShmNosuidMountCount" = "1" ]; then
           OK "6"
        else
            CheckupErr "with check if $i is mounted with nosuid"
        fi
}

CheckNosuidShmMountFix() {
    echo "nothing yet" >>/dev/null
}

CheckNosuidDevShmFstab() {
mpoint="/dev/shm"
echo -n "1.1.15b - Checking  $fstabName for nosuid parameter on $mpoint "
DevShmIfMounted=$(mount | grep "$mpoint" | wc -l)

if [ "$DevShmNosuidFstabCount" = "1" ]; then
    if [ "$DevShmIfMounted" = "0" ]; then
        warn "11" "NOT mounted but exists in $fstabName."
    elif [ "$DevShmIfMounted" = "1" ]; then
        OK "3"
    else
        CheckupErr "with check if $mpoint is mounted since it exists in $FSTAB."
    fi
elif [ "$DevShmNosuidFstabCount" = "0" ]; then
        warn "11" "parameter missing."
else
        CheckupErr "with check if parameter exists in $fstabName for $mpoint."
fi
}

CheckNosuidShmFstabFix() {
echo "nothing yet" >>/dev/null
}

# Noexec on /dev/shm
##

CheckNoexecDevShmMount() {
mpoint="/dev/shm"
echo -n "1.1.16a - Checking $mpoint for noexec  "

        if [ "$DevShmNoexecMountCount" = "0" ]; then
            warn "11"  "NOT mounted with noexec"
        elif [ "$DevShmNoexecMountCount" = "1" ]; then
           OK "6"
        else
            CheckupErr "with check if $i is mounted with noexec"
        fi
}

CheckNoexecShmMountFix() {
    echo "nothing yet" >>/dev/null
}

CheckNoexecDevShmFstab() {
mpoint="/dev/shm"
echo -n "1.1.16b - Checking  $fstabName for noexec parameter on $mpoint "
DevShmIfMounted=$(mount | grep "$mpoint" | wc -l)

if [ "$DevShmNoexecFstabCount" = "1" ]; then
    if [ "$DevShmIfMounted" = "0" ]; then
        warn "11" "NOT mounted but exists in $fstabName."
    elif [ "$DevShmIfMounted" = "1" ]; then
        OK "3"
    else
        CheckupErr "with check if $mpoint is mounted since it exists in $FSTAB."
    fi
elif [ "$DevShmNoexecFstabCount" = "0" ]; then
        warn "11" "parameter missing."
else
        CheckupErr "with check if parameter exists in $fstabName for $mpoint."
fi
}

CheckNoexecShmFstabFix() {
echo "nothing yet" >>/dev/null
}

# sticky bit on all world writable directories
##
CheckStickyBits() {
DirectoriesCount=$(find / -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null | wc -l)
listDirectories=$(find / -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)

echo -n "1.1.17 - Checking  sticky bits for world writable directories "
if [ "$DirectoriesCount" = "0" ]; then
    OK "4"
elif [ "$DirectoriesCount" -gt "0" ]; then
    warn "11"  "There are directories with missing sticky bit:"
    for i in $listDirectories
        do
         echo "................................ $i"
        done
else
    CheckupErr "with check for sticky bit on world writable directories."
fi
}

CheckStickyBitsFix() {
echo "nothing yet" >>/dev/null
}

# check OS release
##
checkOSrelease() {
OS=$(sudo cat /etc/issue | sort -u | grep -i "release" | awk -F" " '{print $1,$2}')
echo -n "1.2    - Checking  Operating System Release "
 if [ "$OS" == "Red Hat" ]; then
    RHEL=$(cat /etc/issue | sort -u | grep -i "release" | awk -F" " '{print $7,$8}')
       Notice "6" "You're running RedHat $RHEL"
 elif [ "$OS" == "Amazon Linux" ]; then
        Notice "6" "You're running `cat /etc/issue | sort -u | grep -i "release"`"
 else
        Notice "6" "Your system is neither Redhat or Amazon"
 fi
}

# enable gpgcheck globally
##
GPGcheck() {
gpg=$(sudo grep -i "gpgcheck" /etc/yum.conf | awk -F"=" '{print $2}')
echo -n "1.3.3 - Checking  if gpgcheck is enabled globally "
if [ "$gpg" = "0" ]; then
    err "5" "NOT enabled"
elif [ "$gpg" = "1" ]; then
    OK "5"
else
    CheckupErr "with check against yum.conf"
fi
}

GPGcheckFix() {
echo "nothinh yet" >/dev/null
}

# disable yum-updatesd
#
checkYumUpdatesd(){
echo -n "1.3.5 - Checking  if yum-updatesd is disabled "
checkYumInstalled=$(rpm -qa yum-updatesd | wc -l)

if [ "$checkYumInstalled" = "0" ]; then
        Notice "6" "OK - package NOT installed."
elif [ "$checkYumInstalled" = "1" ]; then
checkYum=$(/sbin/chkconfig --list yum-updatesd | grep -i "on" | wc -l )
        if [ "$checkYum" = "0" ]; then
                OK "5"
        elif [ "$checkYum" = "1" ]; then
                warn "11" "yum-updatesd is enabled"
        else
                CheckupErr "against chkconfig command"
        fi
else
        CheckupErr "with checkup if yum-updatesd is installed"
fi
}

checkYumUpdatesdFix() {
echo "nothing yet" >/dev/null
}

# Obtain software updates
##
checkUpdates() {
echo -n "1.3.6 - Checking for available updates "

countUpdates=$(/usr/bin/yum --security check-update 2>&1 | grep '^There are ' | awk -F"out of " '{print $2}' | awk -F" " '{print $1}'| wc -l)
Updates=$(/usr/bin/yum --security check-update 2>&1 | grep '^There are ' | awk -F"out of " '{print $2}' | awk -F" " '{print $1}')
none="0"
if [ "$countUpdates" = "0" ]; then
    Notice "7" "System is up to date."
elif [ "$countUpdates" = "1" ]; then
    echo -e "\033[1;36m We have `echo "${Updates}"` updates available. \033[m"
    echo ".................................. run this command to update system: yum update."
else

    CheckupErr "with counting available updates"
fi
}

# Verify Package Integrity using rpm
VerifyPackageIntegrity() {
echo -n "1.3.7 - Checking packages integrity & count for manual audit"
countBadPackages=$(rpm -qVa 2>&1 >&- | grep "^prelink" | wc -l)

if [ "$countBadPackages" -gt "0" ]; then
    warn "11" "There are $countBadPackages files in need of manual attention."
    echo "........................... Please run this command to investigate them:"
    echo -e "........................... sudo rpm -qVa | awk '\$2 != \"c\" { print \$0}' "
elif [ "$countBadPackages" = "0" ]; then
    OK "4"
else
    CheckupErr "something went wrong with verifying packages."
fi
}

VerifyPackageIntegrityFix() {
echo "nothing yet" >/dev/null
}

checkAIDEcrontab() {
echo -n "1.4.2 - Checking AIDE schedule "
AIDEcrontab=$(crontab -u root -l  2>/dev/null| grep -i aide | wc -l)
 if [ "$AIDEcrontab" == "0" ]; then
    err "8" "AIDE not scheduled."
 elif [ "$AIDEcrontab" == "1" ]; then
    OK "8"
 else
    CheckupErr "something went wrong."
 fi
}

checkAIDEcrontabfix() {
echo "nothing yet" >>/dev/null
}

checkAIDEinstalled() {
echo -n "1.4.1 - Checking if AIDE is installed "
AIDEcount=$(rpm -qa aide | wc -l)
 if [ "$AIDEcount" = "0" ]; then
    err "7" "AIDE NOT installed"
 elif [ "$AIDEcount" = "1" ]; then
    OK "7"
    checkAIDEcrontab
 else
    CheckupErr "something went wrong with checking if AIDE is installed."
 fi
}

checkAIDEinstalledFix() {
echo "nothing yet" >/dev/null
}

##
# Secure boot settings:
#

checkGrubOwner() {
grub="/etc/grub.conf"
echo -n "1.6.1 - Checking if root owns $grub file "
grubSymlink=$(ls -lrh $grub | awk -F" " '{print $1}' | grep "l" | wc -l)

if [ "$grubSymlink" = "1" ]; then
#skipNoticeA "$grub is a symlink"
Notice "5" "$grub is a symlink"
echo -n "1.6.1a - Checking if root owns $grub symlink source "
grubsource=$(ls -lrh $grub | awk -F"->" '{print $2}' | sed 's/^...//' )
symlinkPermissionCheck=$(stat -c "%u %g" $grubsource | egrep "0 0" | wc -l)
        if [ "$symlinkPermissionCheck" = "1" ]; then
            OK "4"
        elif [ "$symlinkPermissionCheck" = "0" ]; then
            warn "11" "NOT owned by root!"
        else
            CheckupErr "something went wrong."
        fi
    echo -n "1.6.2  - Checking grub symlink source permissions "
    #grubsourcePermissions=$(stat -c "%a" $grubsource |  egrep ".00" )
    grubsourcePermissions=$(stat -c "%a" $grubsource )
        if [ "$grubsourcePermissions" = "600" ]; then
            OK "5"
        elif [ "$grubsourcePermissions" -gt "600" ]; then
            warn "11" "$grubsourcePermissions - please change it to 600"
        else
            err "5" "something went wrong with check on $grubsource"
        fi

elif [ "$grubSymlink" = "0" ]; then
grubOwnerStat=$(stat -c "%u %g" $grub | egrep "0 0" | wc -l)
    if [ "$grubOwnerStat" = "1" ]; then
            OK "3"
    elif [ "$grubOwnerStat" = "0" ]; then
            warn "11" "NOT owned by root!"
    else
            CheckupErr "something went wrong with checking ownership of $grub file."
    fi
echo -n "1.6.2  - Checking grub symlink source permissions "
    grubPermissions=$(stat -c "%a" $grub )
        if [ "$grubPermissions" = "600" ]; then
            OK "3"
        elif [ "$grubPermissions" -gt "600" ]; then
            warn "11" "$grubPermissions - please change it to 600"
        else
            err "3" "something went wrong with check on $grub"
        fi
else
    CheckupErr "with checking if $grub is a symlink"
fi
}

##
# Secure boot settings:
#
grubPassCheck() {
echo -n "1.6.3  - Checking for password protection on grub "
checkPass=$(grep "^password" ${GRUB} | wc -l)
 if [ "$checkPass" = 0 ]; then
     warn "11" "PASSWORD NOT SET or disabled"
 elif [ "$checkPass" -gt "0" ]; then
    OK "5"
 else
    CheckupErr
 fi
}

##
# Authentication for single user mode:
#
singleModeCheck() {
echo -n "1.6.4  - Checking for password on single user mode "
sysc="/etc/sysconfig/init"
init="/etc/inittab"
checksysc=$(grep "SINGLE" $sysc |grep "sushell"|egrep -v "^#"| wc -l)
checkinit=$(grep "sulogin" $init| egrep -v "^#" | wc -l)
if [ -e "$sysc" ]; then
        if [ "$checksysc" = "1" ]; then
            warn "11" "NOT SET"
        elif [ "$checksysc" = "0" ]; then
            OK "5"
        else
            CheckupErr "check for password against $sysc"
        fi
else
        if [ "$checkinit" = "1" ]; then
            OK "5"
        elif [ "$checkinit" = "0" ]; then
            warn "11" "NOT SET"
        else
            CheckupErr "check for password against $init"
        fi
fi
}

##
# Disable interactive boot:
#
checkInteractiveBoot() {
echo -n "1.6.5  - Checking if interactive boot is disabled "
init="/etc/sysconfig/init"
prompt=$(grep "^PROMPT" $init |awk -F"=" '{print $2}')
 if [ "$prompt" = "yes" ]; then
        warn "11" "ENABLED"
 elif [ "$prompt" = "no" ]; then
        OK "5"
 else
       CheckupErr
 fi
}

##
# Additional Process Hardening:
#
#
checkRestrictionCoreDumps() {
limitsfile="/etc/security/limits.conf"

checkCoreDumpsLimits() {
echo -n "1.7.1a - Checking if hard limit is set on core dumps "
hardcheck=$(grep "hardcore" $limitsfile | egrep -v "^#" |wc -l)
 if [ "$hardcheck" = "0" ]; then
    err "5" "NOT SET"
 elif [ "$hardcheck" = "1" ]; then
    OK "5"
 else
    CheckupErr
 fi
}

checkProgramCoreLimits() {
echo -n "1.7.1b - Checking if setuid programs can dump core "
programCheck=$(grep -i "dumpable" /etc/sysctl.conf |egrep -v "^#"| wc -l)
 if [ "$programCheck" = "0" ]; then
    err "5" "NOT SET"
 elif [ "$programCheck" = "1" ]; then
    OK "5"
 else
    CheckupErr
 fi
}

checkCoreDumpsLimits
checkProgramCoreLimits
}

##
# Disable interactive boot:
#
checkBufferOverFlowProtection() {
echo -n "1.7.2 - Checking if buffer overflow protection is enabled "
showShield=$(sysctl kernel.exec-shield 2>&1| awk -F"= " '{print $2}')
checkShield=$(sysctl kernel.exec-shield 2>&1  | grep "error:" | awk -F":" '{print $1}')
 if [ "$checkShield" = "error" ]; then
    err "4" "kernel parameter missing"
 else
    if [ "$showShield" = "1" ]; then
        OK "4"
    else
        err "4" "NOT ENABLED"
    fi
 fi
}

#
# Enable randomized virtual memory region placement:
#

checkRandomizedVAspace() {
echo -n "1.7.3 - Checking if protection against writing memory page exploits is enabled "
checkKernelParameter=$(sysctl kernel.randomize_va_space | awk -F"= " '{print $2}')
 if [ "$checkKernelParameter" = "2" ]; then
    OK "2"
 elif [ "$checkKernelParameter" = "1" ]; then
    OK "2"
 elif [ "$checkKernelParameter" = "0" ]; then    
    warn "11" "DISABLED"
 else
    CheckupErr
 fi
}

#
# Enable XD/NX support:
#
# - prevent  buffer overflow protection
checkNXsupport() {
checkCPUpae=$(egrep "^flags" /proc/cpuinfo  | sed -e 's/\s\+/\n/g' | grep "pae" | wc -l)
checkCPUnx=$(egrep "^flags" /proc/cpuinfo  | sed -e 's/\s\+/\n/g' | grep "nx" | wc -l)
checkKernelPAE=$(uname -r | sed 's/\./\t/g' |sed -e 's/\s\+/\n/g' | grep -i "pae" | wc -l)
checkPAEinstall=$(rpm -qa | grep -i "pae" | wc -l)

checkPAE() {
echo -n "1.7.4b - Checking if PAE kernel is installed on the system  "
 if [ "$checkPAEinstall" = "0" ]; then
    warn "11" "not INSTALLED"
 else
    OK "4"
    echo -n "1.7.4c - Checking if PAE kernel is used on running system  "
        if [ "$checkKernelPAE" = "0" ]; then
            warn "11" "Not USED"
        elif [ "$checkKernelPAE" = "1" ]; then
            OK "4"
        else
            CheckupErr
        fi
 fi
}

echo -n "1.7.4a - Checking if NX No Execute & PAE is supported by CPU "
if [ "$checkCPUpae" = "1" ] && [ "$checkCPUnx" = "1" ]; then
    OK "4"
    checkPAE
elif [ "$checkCPUpae" = "1" ] && [ "$checkCPUnx" = "0" ]; then
    warn "11" "PAE supported by CPU but NX is not"
        checkPAE
elif [ "$checkCPUpae" = "0" ] && [ "$checkCPUnx" = "1" ]; then
    warn "11" "PAE NOT supported by CPU but NX is"
        checkPAE
elif [ "$checkCPUpae" = "0" ] && [ "$checkCPUnx" = "0" ]; then
    err "4" "PAE & NX NOT supported by this CPU"
fi
}

#
# Check if prelink is disabled:
#
checkPrelink() {
IsPrelinkInstalled=$(rpm -qa | grep -i "prelink" | wc -l)
echo -n "1.7.5a - Checking if Prelink is installed on the system "
if [ "$IsPrelinkInstalled" = "0" ]; then
    Notice "4" "Not Installed"
elif [ "$IsPrelinkInstalled" = "1" ]; then
IsPrelinkEnabled=$(grep "PRELINKING" /etc/sysconfig/prelink  | awk -F"=" '{print $2}' )
    OK "4"
    echo -n "1.7.5b - Checking if Prelink is enabled "
     if [ "$IsPrelinkEnabled" = "yes" ]; then
        warn "11" "ENABLED"
     elif [ "$IsPrelinkEnabled" = "no" ]; then
        OK "4"
     else
        CheckupErr "with check if prelink is enabled"
     fi
else
    CheckupErr " with check if prelink is installed"
fi
}

#
# Check client-server deamons
#
checkServerClientServices() {
COUNTER="2"
services="rsh nis tftp talk" # based on our custom environment we're disabling telnet check
for i in $services
 do
  options="client server"
        for c in ${options}
         do

checkDeamonService() {
service=$1
option=$2
                if [ "$c" = "client" ]; then
IsClientInstalled=$(rpm -qa | grep -i "${service}" | grep -v "server" | wc -l)
echo -n "2.1.${COUNTER} - Checking if ${service} client is NOT installed "
 if [ "$IsClientInstalled" = "1" ]; then
                warn "11" "INSTALLED"
 elif [ "$IsClientInstalled" = "0" ]; then
                OK "5"
 else
                CheckupErr
 fi
                elif [ "$c" = "server" ]; then
IsServerInstalled=$(rpm -qa | grep -i "${service}" | grep "server" | wc -l)
echo -n "2.1.${COUNTER}a - Checking if ${service} server is NOT installed "
 if [ "$IsServerInstalled" = "1" ]; then
        warn "11" "INSTALLED"
 echo -n "2.1.${COUNTER}b - Checking if ${service} server is disabled "
 IsServerEnabled=$(chkconfig --list | grep -i "${service}" | awk -F" " '{print $2}')
        if [ "$IsServerEnabled" = "on" ]; then
                err "5" "ENABLED"
        elif [ "$IsServerEnabled" = "off" ]; then
                warn "11" "installed but NOT enabled"
        else
                CheckupErr
        fi
 elif [ "$IsServerInstalled" = "0" ]; then
        OK "5"
 else
        CheckupErr
 fi
                else
                        CheckupErr
                fi
}

COUNTER=$((COUNTER+1))
isEvenNo=$( expr $COUNTER % 2 )
 if [ $isEvenNo -ne 0 ]
        then
checkDeamonService  ${i} ${c}
 else
checkDeamonService  ${i} ${c}
 fi
        done
 done
}

#
# Check xinetd
#
checkXinetdService() {
IsXinetdInstalled=$(rpm -qa | grep -i "xinetd" | wc -l)
echo -n "2.1.11 - Checking if xinetd is NOT installed "
 if [ "$IsXinetdInstalled" = "1" ]; then
    warn "11" "INSTALLED"
 elif [ "$IsXinetdInstalled" = "0" ]; then
    OK "6"
 else
    CheckupErr
 fi
}

##
## Check stream-dgram services:
##
checkStreamDgramServices() {
COUNTER="1"
services="chargen daytime echo"

for i in ${services}
 do
  options="dgram stream"
        for b in ${options}
         do

checkService() {
service=$1
option=$2
IsServiceAdded=$(chkconfig --list | grep -i "${service}-${option}" | wc -l)
IsServiceEnabled=$(chkconfig --list | grep -i "${service}-${option}" | awk -F" " '{print $2}')

echo -n "2.1.1${COUNTER} - Checking if ${service}-${option} service is NOT enabled "
if [ "$IsServiceAdded" = "1" ]; then
        if [ "$IsServiceEnabled" = "on" ]; then
                err "4" "ENABLED"
        elif [ "$IsServiceEnabled" = "off" ]; then
                warn "11" "added but NOT enabled"
        else
                CheckupErr
        fi
elif [ "$IsServiceAdded" = "0" ]; then
 OK "4"
else
 CheckupErr
fi
}

COUNTER=$((COUNTER+1))
isEvenNo=$( expr $COUNTER % 2 )
 if [ $isEvenNo -ne 0 ]
        then
checkService ${i} ${b}
 else
checkService ${i} ${b}
 fi
        done
 done
}

#
# Check tcpmux-server
#
checkTcpmuxServer() {
service="tcpmux"
option="server"
IsServiceAdded=$(chkconfig --list | grep -i "${service}-${option}" | wc -l)
IsServiceEnabled=$(chkconfig --list | grep -i "${service}-${option}" | awk -F" " '{print $2}')

echo -n "2.1.18 - Checking if ${service}-${option} service is NOT enabled "
if [ "$IsServiceAdded" = "1" ]; then
        if [ "$IsServiceEnabled" = "on" ]; then
                err "4" "ENABLED"
        elif [ "$IsServiceEnabled" = "off" ]; then
                warn "11" "added but NOT enabled"
        else
                CheckupErr
        fi
elif [ "$IsServiceAdded" = "0" ]; then
 OK "4"
else
 CheckupErr
fi
}

#
# Check umask
#
checkUmask() {
sysconfig="/etc/sysconfig/init"
IsUmaskSet=$(grep -i "umask" ${sysconfig} | wc -l)

echo -n "3.1a Checking if umask is set "
if [ "$IsUmaskSet" = "0" ]; then
   err "8" "NOT SET in ${sysconfig}"
elif [ "$IsUmaskSet" = "1" ]; then
    OK "8" "parameter set."
    echo -n "3.1b Checking umask value "
    umaskValue=$(grep -i "umask" ${sysconfig}| awk -F" " '{print $2}')
    requiredUmask="027"
        if [ "$umaskValue" != "027" ]; then
           warn "11" "not set to 027"
        elif [ "$umaskValue" = "027" ]; then
            OK "8"
        else
            CheckupErr
        fi
else
       CheckupErr
fi
}

#
# Check Xwindow
#
checkXwindow() {
echo -n "3.2a Checking if X Window system is NOT installed "
XwindowInstalled=$(yum grouplist "X Window System" 2>&1 | grep "Done" -B 1 | grep "System" | wc -l)
 if [ "$XwindowInstalled" = "0" ]; then
     OK "5"
 elif [ "$XwindowInstalled" = "1" ]; then
    warn "11" "INSTALLED"
    echo -n "3.2b Checking if X Window system is disabled at boot "
    DefaultMode=$(grep "^id:" /etc/inittab | awk -F":" '{print $2}')
     if [ "$DefaultMode" = "5" ]; then
        warn "11" "ENABLED"
     else
       OK "5"
     fi
 else
     CheckupErr
 fi
}

#
# Secure avahi service if enabled
#
checkAvahiProtocols() {
echo -n "3.3.1 Checking which protocol is used for Avahi Server  "
avahiConf="/etc/avahi/avahi-daemon.conf"
Protocol1=$(grep "use-ipv4" /etc/avahi/avahi-daemon.conf | awk -F"=" '{print $2}')
Protocol2=$(grep "use-ipv6" /etc/avahi/avahi-daemon.conf | awk -F"=" '{print $2}')
 if [ "$Protocol1" = "yes" ] && [ "$Protocol1" = "$Protocol2" ]; then
        warn "11" "both are enabled"
 elif [ "${Protocol1}" == "no" ] && [ "${Protocol1}" == "${Protocol2}" ]; then
        Notice "4" "- both protocols are disabled"                    # fix this line
 elif [ "${Protocol1}" == "yes" ] && [ "${Protocol1}" != "${Protocol2}" ]; then
        Notice "4" " - enabled on ipv4"                            # fix this line
 elif [ "${Protocol2}" == "yes" ] && [ "${Protocol2}" != "${Protocol1}" ]; then
        Notice "4" " - enabled on ipv6"                            # fix this line
 else
        CheckupErr
 fi
}

#
# Check Avahi parameters
#
AvahiParameterChecks() {
COUNTER="1"
avahiConf="/etc/avahi/avahi-daemon.conf"
parameters="check-response-ttl disallow-other-stacks disable-publishing"

for i in ${parameters}
 do
COUNTER=$((COUNTER+1))
echo -n "3.3.${COUNTER} Checking if $i is ENABLED for Avahi Server "
isParameterDisabled=$(grep "$i" ${avahiConf} | grep "^#" | wc -l)

check1() {
 if [ "$isParameterDisabled" = "1" ]; then
        warn "11" "DISABLED"
 elif [ "$isParameterDisabled" = "0" ]; then
ParameterValue=$(grep "^${i}" ${avahiConf} | awk -F"=" '{print $2}')
        if [ "$ParameterValue" = "yes" ]; then
                OK "3"
        elif [ "$ParameterValue" = "no" ]; then
                warn "11" "set to no"
        else
                CheckupErr
        fi
 else
        CheckupErr
 fi
}

publishingChecks() {
 if [ "$isParameterDisabled" = "1" ]; then
        warn "11" "DISABLED"
 elif [ "$isParameterDisabled" = "0" ]; then
ParameterValue=$(grep "^${i}" ${avahiConf} | awk -F"=" '{print $2}')
        if [ "$ParameterValue" = "yes" ]; then
                OK "3"
publishParameters1=$(grep "publish" ${avahiConf} | grep "^#" | wc -l)
publishParameters2=$(grep "^publish" ${avahiConf}  | wc -l)
echo -n "3.3.5 Checking if Publishing parameters are ENABLED for Avahi Server "
         if [ "$publishParameters1" = "0" ] && [ "$publishParameters2" = "0" ]; then
                echo "no publishing parameters found"
         elif [ "$publishParameters1" -gt "0" ] && [ "$publishParameters2" = "0" ]; then
                warn "11" "$publishParameters1 parameters found but commented out"
         elif [ "$publishParameters2" -gt "0" ] && [ "$publishParameters1" = "0" ]; then
skipNoticeA "$publishParameters2 parameters enabled"
EnabledPublishParameters=$(grep "^publish" ${avahiConf} | sed ':a;N;$!ba;s/\n/ /g')
                for b in ${EnabledPublishParameters}
                 do
ParameterName=$(echo $b | awk -F"=" '{print $1}')
ParameterValue=$(echo $b | awk -F"=" '{print $2}')
                  if [ "$ParameterValue" = "yes" ]; then
                        warn "11" "$ParameterName is set to YES"
                  elif [ "$ParameterValue" = "no" ]; then
                        OK "3"
                  else
                        CheckupErr  "with check for the values of enabled parameters."
                  fi
                 done
          elif [ "$publishParameters1" -gt "0" ] && [ "$publishParameters2" -gt "0" ]; then
warn "11" "publishing parameters enabled"
EnabledPublishParameters=$(grep "^publish" ${avahiConf} | sed ':a;N;$!ba;s/\n/ /g')
COUNTER2="0"
                for c in ${EnabledPublishParameters}
                 do
COUNTER2=$((COUNTER2+1))
ParameterName=$(echo $c | awk -F"=" '{print $1}')
ParameterValue=$(echo $c | awk -F"=" '{print $2}')
echo -n "3.3.5.${COUNTER2} Checking value of ${ParameterName} "
                  if [ "$ParameterValue" = "yes" ]; then
                        warn "11" "$ParameterName is set to YES"
                  elif [ "$ParameterValue" = "no" ]; then
                        OK "6" "OK - set correctly."
                  else
                        CheckupErr "with check for values of enabled pars where we have enabled and commented out."
                  fi
                 done
         else
                CheckupErr "with checks for parameters."
         fi
        elif [ "$ParameterValue" = "no" ]; then
                warn "11" "set to no"
        else
                CheckupErr
        fi
 else
        CheckupErr
 fi
}

 if [ "$i" = "disable-publishing" ]; then
  publishingChecks
 else
  check1
 fi

done
}

#
# Check Avahi
#
checkAvahi() {
echo -n "3.3 Check if Avahi Server is disabled "
IsAvahiEnabled=$(chkconfig --list | grep -i avahi| sed -e 's/\s\+/\n/g' | grep "on" | grep -v "avahi" | wc -l)
 if [ "$IsAvahiEnabled" -gt "0" ]; then
        AvahiEnabled=$(chkconfig --list | grep -i avahi| sed -e 's/\s\+/\n/g' | grep "on" | grep -v "avahi" | awk -F":" '{print $1}' | sed -e ':a;N;$!ba;s/\n/ /g')
        warn "11" "Enabled on these runlevels: ${AvahiEnabled}."
        checkAvahiProtocols
        AvahiParameterChecks
 elif [ "$IsAvahiEnabled" = "0" ]; then
        OK "7"
 else
        CheckupErr
 fi
}

#
# Check CUPS
#
checkCUPSservice() {
IsCUPSenabled=$(chkconfig --list | grep -i "cups" | wc -l)
echo -n "3.4 - Checking if CUPS server is NOT enabled  "
 if [ "$IsCUPSenabled" = "0" ]; then
        OK "6"
 elif [ "$IsCUPSenabled" = "1" ]; then
        warn "11" "ENABLED"
 else
        CheckupErr
 fi
}

#
# Check DHCP
#
checkDHCPservice() {
IsDHCPinstalled=$(yum list dhcp 2>/dev/null | grep "dhcp" | wc -l)
IsDHCPenabled=$(chkconfig --list | grep -i "dhcp" | wc -l)
echo -n "3.5a - Checking if DHCP server is NOT installed  "
 if [ "$IsDHCPinstalled" = "0" ]; then
        OK "5"
 elif [ "$IsDHCPinstalled" -gt "0" ]; then
        warn "11" "installed"
echo -n "3.5b - Checking if DHCP server is NOT enabled  "
         if [ "$IsDHCPenabled" = "0" ]; then
                OK "6"
         elif [ "$IsDHCPenabled" -gt "0" ]; then
                err "6" "ENABLED"
         else
                CheckupErr
         fi
 else
        CheckupErr
 fi
}

#
# Check NTP Service
#
checkNTPservice() {
ntpConfig="/etc/ntp.conf"
IsNTPinstalled=$(rpm -qa | grep "ntp" | wc -l)
IsNTPenabled=$(chkconfig --list | grep "ntp" | wc -l)

echo -n "3.6a Checking if NTP package is installed"
if [ "$IsNTPinstalled" = "0" ]; then
        warn "11" "NOT installed"
elif [ "$IsNTPinstalled" -gt "0" ]; then
        OK "6"

echo -n "3.6b Checking if NTP package is enabled"
 if [ "$IsNTPenabled" = "0" ]; then
        warn "11" "NOT enabled"
 elif [ "$IsNTPenabled" -gt "0" ]; then
        OK "7"
echo -n "3.6c Checking if NTP configuration exists"
   if [ -e "$ntpConfig" ]; then
        OK "6"
echo -n "3.6d Checking if NTP is configured with 'restrict default' parameters"
   ntpParameters=$(grep -i "restrict default" ${ntpConfig} | wc -l)
        if [ "$ntpParameters" = "0" ]; then
                warn "11" "NOT configured"
        elif [ "$ntpParameters" -gt "0" ]; then
                OK "3"
        else
                CheckupErr
        fi
echo -n "3.6e Checking if NTP is configured with 'restrict -6 default' parameters"
   ntpParameters2=$(grep -i "restrict -6 default" ${ntpConfig} | wc -l)
        if [ "$ntpParameters2" = "0" ]; then
                warn "11" "NOT configured"
        elif [ "$ntpParameters2" -gt "0" ]; then
                OK "2"
        else
                CheckupErr
        fi
echo -n "3.6f Checking if NTP is configured as a server"
 ntpServer=$(grep "^server" ${ntpConfig} | wc -l)
        if [ "$ntpServer" = "0" ]; then
                warn "11" "NOT configured"
        elif [ "$ntpServer" -gt "0" ]; then
                OK "6"
        else
                CheckupErr
        fi
echo -n "3.6g Checking if NTP deamon can run as unprivileged user"
 ntpUser=$(grep "ntp:ntp" /etc/sysconfig/ntpd | grep "OPTIONS" | wc -l)
        if [ "$ntpUser" = "0" ]; then
                warn "11" "NOT configured"
        elif [ "$ntpUser" -gt "0" ]; then
                OK "4"
        else
                CheckupErr
        fi
   else
    warn "11" "${ntpConfig} NOT found"
   fi
 else
  CheckupErr
 fi
else
        CheckupErr
fi
}

#
# Check NFS/RPC service
#
checkNFSRPCservice() {
packages="nfslock rpcgssd rpcidmapd portmap"
COUNTERA="0"

for item in $packages
 do
ItemIsEnabled=$(chkconfig --list | grep "${item}" | sed -e 's/\s\+/\n/g' | awk -F":" '{print $2}' | sort -u | sed '/^$/d' | grep "on" | wc -l )
COUNTERA=$((COUNTERA+1))
 echo -n "3.8.${COUNTERA} Checking if ${item} is disabled"
  if [ "${ItemIsEnabled}" = "0" ]; then
        OK "7"
  elif [ "${ItemIsEnabled}" -gt "0" ]; then
checkLevels=$(chkconfig --list | grep "${item}" | sed -e 's/\s\+/\n/g' | grep "on" | awk -F":" '{print $1}' | sed ':a;N;$!ba;s/\n/ /g')
        warn "11" "ENABLED on runlevels: ${checkLevels}"
  else
        CheckupErr
  fi
done
}

#
# Check BIND & VSFTPD
#
checkServices() {
services="bind vsftpd"
COUNTERB="8"

for s in $services
 do
COUNTERB=$((COUNTERB+1))
IsServiceInstalled=$(rpm -qa ${s} | wc -l)
IsServiceDisabled=$(chkconfig --list | grep -i "${s}" | wc -l)
 echo -n "3.${COUNTERB}a Checking if ${s} server is NOT installed"
if [ "$IsServiceInstalled" = "0" ]; then
        OK "5"
elif [ "$IsServiceInstalled" -gt "0" ]; then
        warn "11" "installed"
echo -n "3.${COUNTERB}b Checking if ${s} server is DISABLED"
        if [ "$IsServiceDisabled" = "0" ]; then
                OK "5"
        elif [ "$IsServiceDisabled" -gt "0" ]; then
                err "5" "ENABLED"
        else
                CheckupErr
        fi
else
        CheckupErr
fi
 done
}

#
# Check dovecot, samba, net-snmp
#

checkServices2() {
services="dovecot samba net-snmp"
COUNTERB="11"
for s in $services
 do
if [ "$s" = "net-snmp" ]; then
  COUNTERB=$((COUNTERB+2))
  IsServiceInstalled=$(rpm -qa ${s} | wc -l)
  IsServiceDisabled=$(chkconfig --list | grep -i "${s}" | wc -l)
echo -n "3.${COUNTERB}a Checking if ${s} server is NOT installed"
  if [ "$IsServiceInstalled" = "0" ]; then
          OK "5"
  elif [ "$IsServiceInstalled" -gt "0" ]; then
          warn "11" "installed"
  echo -n "3.${COUNTERB}b Checking if ${s} server is DISABLED"
          if [ "$IsServiceDisabled" = "0" ]; then
                  OK "5"
          elif [ "$IsServiceDisabled" -gt "0" ]; then
                  err "5" "ENABLED"
          else
                  CheckupErr
          fi
  else
          CheckupErr
  fi
else
  COUNTERB=$((COUNTERB+1))
  IsServiceInstalled=$(rpm -qa ${s} | wc -l)
  IsServiceDisabled=$(chkconfig --list | grep -i "${s}" | wc -l)
echo -n "3.${COUNTERB}a Checking if ${s} server is NOT installed"
  if [ "$IsServiceInstalled" = "0" ]; then
          OK "5"
  elif [ "$IsServiceInstalled" -gt "0" ]; then
          warn "11" "installed"
  echo -n "3.${COUNTERB}b Checking if ${s} server is DISABLED"
          if [ "$IsServiceDisabled" = "0" ]; then
                  OK "5"
          elif [ "$IsServiceDisabled" -gt "0" ]; then
                  err "5" "ENABLED"
          else
                  CheckupErr
          fi
  else
          CheckupErr
  fi
fi
 done
}

#
# Check smtp
#
checkSMTP() {
IsSMPTlocal=$(netstat -an | grep LIST | grep :25 | grep "127.0.0.1" | wc -l)

echo -n "3.16 Checking if MTA is listening on loopback address"
if [ "$IsSMPTlocal" = "1" ]; then
        OK "5"
elif [ "$IsSMPTlocal" = "0" ]; then
SMTPlisteningAddress=$(netstat -an | grep LIST | grep :25 | grep -v "::" | awk -F" " '{print $4}' | awk -F":" '{print $1}')
        warn "11" "listening on ${SMTPlisteningAddress} "
else
        CheckErr
fi
}

#
# Check Host Only Network Parameters
#
checkHostOnlyNetworkParameters() {
parameters="net.ipv4.ip_forward net.ipv4.conf.all.send_redirects net.ipv4.conf.default.send_redirects"
COUNTERC="0"
 for t in $parameters
  do
COUNTER=$((COUNTERC+1))
parameter="Forwarding"
    if [ "$t" = "net.ipv4.ip_forward" ]; then
     parameter="Forwarding"
     echo -n "4.1.${COUNTER} Checking if ${parameter} is DISABLED"
IsForwardingDisabled=$(/sbin/sysctl ${t} | awk -F"= " '{print $2}')
        if [ "$IsForwardingDisabled" = "0" ]; then
            OK "6"
        elif [ "$IsForwardingDisabled" != "0" ]; then
            err "6" "ENABLED"
        else
            CheckupErr
        fi
    elif [ "$t" = "net.ipv4.conf.all.send_redirects" ]; then
     parameter="All Send Packet Redirects"
     echo -n "4.1.${COUNTER}.a Checking if ${parameter} is DISABLED"
IsForwardingDisabled=$(/sbin/sysctl ${t} | awk -F"= " '{print $2}')
        if [ "$IsForwardingDisabled" = "0" ]; then
            OK "4"
        elif [ "$IsForwardingDisabled" != "0" ]; then
            err "4" "ENABLED"
        else
            CheckupErr
        fi
    elif [ "$t" = "net.ipv4.conf.default.send_redirects" ]; then
     parameter="Default Send Packet Redirects"
     echo -n "4.1.2.b Checking if ${parameter} is DISABLED"
IsForwardingDisabled=$(/sbin/sysctl ${t} | awk -F"= " '{print $2}')
        if [ "$IsForwardingDisabled" = "0" ]; then
            OK "4"
        elif [ "$IsForwardingDisabled" != "0" ]; then
            err "4" "ENABLED"
        else
            CheckupErr
        fi
    fi    
  done
}

#
# Check Host/Router parameters
#
checkNetworkHostRouterParameters() {
ALL="net.ipv4.conf.all"
DEF="net.ipv4.conf.default"
IPV="net.ipv4"
parameters="${ALL}.accept_source_route ${DEF}.accept_source_route ${ALL}.accept_redirects ${DEF}.accept_redirects ${ALL}.secure_redirects ${DEF}.secure_redirects ${ALL}.log_martians ${IPV}.icmp_echo_ignore_broadcasts ${IPV}.icmp_ignore_bogus_error_responses ${ALL}.rp_filter ${DEF}.rp_filter ${IPV}.tcp_syncookies"
COUNTERAA="0"
COUNTERA="0"
COUNTERB="0"
COUNTERC="0"
COUNTERD="0"
 for t in $parameters
  do
IsParameterDisabled() {
ParameterValue=$(/sbin/sysctl ${t} | awk -F"= " '{print $2}')
tab="$1"
        if [ "$ParameterValue" = "0" ]; then
     OK "$tab"
        elif [ "$ParameterValue" != "0" ]; then
     err "$tab" "ENABLED"
        else
     CheckupErr
        fi
}

IsParameterEnabled() {
ParameterValue=$(/sbin/sysctl ${t} | awk -F"= " '{print $2}')
tab="$1"
        if [ "$ParameterValue" = "1" ]; then
     OK "$tab"
        elif [ "$ParameterValue" != "1" ]; then
     err "$tab" "DISABLED"
        else
     CheckupErr
        fi
}

parameter="Routing"
        if [ "$t" = "${ALL}.accept_source_route" ]; then
COUNTERA=$((COUNTERA+1))
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.1.1
     parameter="All Source Routed Packets"
         echo -n "4.2.${COUNTERAA}.${COUNTERA} Checking if ${parameter} is DISABLED"
IsParameterDisabled "4"
        elif [ "$t" = "${DEF}.accept_source_route" ]; then
COUNTERA=$((COUNTERA+1))  # -- 4.2.1.2
     parameter="Default Source Routed Packets"
         echo -n "4.2.${COUNTERAA}.${COUNTERA} Checking if ${parameter} is DISABLED"
IsParameterDisabled "4"
        elif [ "$t" = "${ALL}.accept_redirects" ]; then
COUNTERB=$((COUNTERB+1))
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.2.1
     parameter="ALL ICMP redirect messages"
         echo -n "4.2.${COUNTERAA}.${COUNTERB} Checking if ${parameter} is DISABLED"
IsParameterDisabled "4"
        elif [ "$t" = "${DEF}.accept_redirects" ]; then
COUNTERB=$((COUNTERB+1)) # -- 4.2.2.2
     parameter="Default ICMP redirect messages"
         echo -n "4.2.${COUNTERAA}.${COUNTERB} Checking if ${parameter} is DISABLED"
IsParameterDisabled "4"
        elif [ "$t" = "${ALL}.secure_redirects" ]; then
COUNTERAA=$((COUNTERAA+1))
COUNTERC=$((COUNTERC+1)) # -- 4.2.3.1
     parameter="ALL Secure ICMP Redirect Messages"
         echo -n "4.2.${COUNTERAA}.${COUNTERC} Checking if ${parameter} is DISABLED"
IsParameterDisabled "3"
        elif [ "$t" = "${DEF}.secure_redirects" ]; then
COUNTERC=$((COUNTERC+1)) # -- 4.2.3.2
     parameter="Default Secure ICMP Redirect Messages"
         echo -n "4.2.${COUNTERAA}.${COUNTERC} Checking if ${parameter} is DISABLED"
IsParameterDisabled "3"
        elif [ "$t" = "${ALL}.log_martians" ]; then
COUNTERAA=$((COUNTERAA+1))
     parameter="Logging for Suspicious packets"
         echo -n "4.2.${COUNTERAA} Checking if ${parameter} is ENABLED"
IsParameterEnabled "4"
        elif [ "$t" = "${IPV}.icmp_echo_ignore_broadcasts" ]; then
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.5
     parameter="ALL ICMP echo & timestamp requests to Broadcast & Multicast addresses"
         echo -n "4.2.${COUNTERAA} Checking if ${parameter} are IGNORED"
IsParameterEnabled "1"
        elif [ "$t" = "${IPV}.icmp_ignore_bogus_error_responses" ]; then
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.6
     parameter="Bad Error Message Protection"
         echo -n "4.2.${COUNTERAA} Checking if ${parameter} is ENABLED"
IsParameterEnabled "4"
        elif [ "$t" = "${ALL}.rp_filter" ]; then
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.7.1
COUNTERD=$((COUNTERD+1))
     parameter="All RFC-recommended source route validation"
         echo -n "4.2.${COUNTERAA}.${COUNTERD} Checking if ${parameter} is ENABLED"
IsParameterEnabled "2"
        elif [ "$t" = "${DEF}.rp_filter" ]; then
COUNTERD=$((COUNTERD+1))
     parameter="Default RFC-recommended source route validation"
         echo -n "4.2.${COUNTERAA}.${COUNTERD} Checking if ${parameter} is ENABLED"
IsParameterEnabled "2"
        elif [ "$t" = "${IPV}.tcp_syncookies" ]; then
COUNTERAA=$((COUNTERAA+1)) # -- 4.2.8
     parameter="TCP SYN Cookies" # - this allows the server to accept valid connections under denial of service attack
         echo -n "4.2.${COUNTERAA} Checking if ${parameter} is ENABLED"
IsParameterEnabled "6"
        else
                CheckupErr
        fi
  done
}

checkTcpWrappers() {
echo -n "4.5 - Checking if TCP Wrappers are installed "
AreTcpWrappersInstalled=$(rpm -qa | grep "tcp_wrappers-[0-9]" | wc -l)
if [ "$AreTcpWrappersInstalled" = "1" ]; then
        OK "6"
elif [ "$AreTcpWrappersInstalled" = "0" ]; then
        err "6" "NOT Installed"
else
        CheckupErr
fi
}

checkHostAllowDeny() {

hostsConfigExists() {
configFiles="/etc/hosts.allow /etc/hosts.deny"
COUNTERA="0"
COUNTERB="1"

checkConfigFile() {
HostsFile="$1"
 if [ -e $HostsFile ]; then
        AreThereRules=$(cat $HostsFile | egrep -v "^#" | wc -l)
         if [ "$AreThereRules" == "0" ]; then
                warn "11" "Exists but seems to have no rules."
         elif [ "$AreThereRules" -gt "0" ]; then
                OK "6"
         else
                CheckupErr "with checking for rules."
         fi
 else
        err "6" "DOES NOT EXISTS"
 fi
}

for configFile in ${configFiles}
 do
checkConfigPermissions() {
checkPermissions=$(stat -c "%a" $configFile)
 if [ "${checkPermissions}" == "644" ]; then
        OK "6"
 elif [ "${checkPermissions}" != "644" ]; then
        warn "11" "WRONG PERMISSIONS"
 else
        CheckupErr
 fi
}

  if [ "$configFile" = "/etc/hosts.allow" ]; then
COUNTERA=$((COUNTERA+1))
COUNTERB=$((COUNTERB+1))
echo -n "4.5.${COUNTERA} Checking if ${configFile} exists "
checkConfigFile ${configFile}
echo -n "4.5.${COUNTERB} Checking permissions on $HostsFile "
  elif [ "$configFile" = "/etc/hosts.deny" ]; then
COUNTERA=$((COUNTERA+2))
COUNTERB=$((COUNTERB+2))
checkConfigPermissions
echo -n "4.5.${COUNTERA} Checking if ${configFile} exists "
checkConfigFile ${configFile}
echo -n "4.5.${COUNTERB} Checking permissions on $HostsFile "
checkConfigPermissions
  else
        CheckupErr
  fi
done
}

hostsConfigExists
}

checkIPtables() {
IsIPtablesSetup=$(chkconfig --list iptables | wc -l)
IPtablesLevels=$(chkconfig --list iptables | sed -e 's/\s\+/\n/g' | grep "on" | awk -F":" '{print $1}' | sed -e ':a;N;$!ba;s/\n/ /g')

echo -n "4.6.1 Checking if iptables is configured "
if [ "${IsIPtablesSetup}" -gt "0" ]; then
        Notice "6" "OK - ENABLED on these runlevels: ${IPtablesLevels}"
echo -n "4.6.2 Checking if iptables is currently running "
IsDeamonRunning=$(service iptables status | head -1 | awk -F":" '{print $2}')
IsDeamonRunning2=$(service iptables status | head -1 | awk -F":" '{print $1}')
        if [ "${IsDeamonRunning}" == " Firewall is not running." ]; then
                warn "11" "NOT RUNNING"
        elif [ "${IsDeamonRunning}" == " filter" ]; then
                OK "5"
        elif [ "${IsDeamonRunning2}" == "Table" ]; then
                OK "5"
        else
                CheckupErr
        fi
elif [ "${IsIPtablesSetup}" == "0" ]; then
        err "6" "NOT configured"
else
        CheckupErr
fi
}

checkUncommonProtocols() {
protocols="dccp sctp rds tipc"
modprobe="/etc/modprobe.conf"
COUNTER="0"

for a in ${protocols}
 do
COUNTER=$((COUNTER+1))
echo -n "4.8.${COUNTER} Checking if ${a} Protocol is Disabled "
if [ -e ${modprobe} ]; then
isProtocolDisabled=$(grep "install ${a} /bin/true" ${modprobe} | wc -l)
        if [ "$isProtocolDisabled" == "1" ]; then
                OK "6"
        elif [ "$isProtocolDisabled" != "1" ]; then
                err "6" "${a} Enabled"
        else
                CheckupErr
        fi
else
 err "6" " ${modprobe} file missing"
fi
 done
}

checkSyslog() {
IsSyslogEnabled=$(/sbin/chkconfig --list | grep "^syslog" | wc -l)
echo -n "5.1.1 Checking if syslog is configured  "
 if [ "$IsSyslogEnabled" == "1" ]; then
IsItRunning=$(/etc/init.d/syslog status | grep "syslogd" |awk -F"is " '{print $2}')
    if [ "$IsItRunning" == "running..." ]; then
     Notice "6" "OK - running but IT IS RECOMMENDED TO USE rsyslog instead."
syslogConf="/etc/syslog.conf"
        if [ -e "$syslogConf" ]; then
# check configs
syslogParameters="auth,user kern daemon syslog lpr,news,uucp,local0,local1"
COUNTERC="0"
for i in $syslogParameters
    do
checkLogDestination=$(grep ${i} $syslogConf| awk -F" " '{print $2}' )
            if [ $i == "auth,user" ]; then
COUNTER=$((COUNTERC+1))
echo -n "5.1.1.${COUNTER} Checking if $i notifications are configured   "
checkParameterExistence=$(grep ${i} $syslogConf | wc -l )
                if [ $checkParameterExistence == "1" ]; then
                    if [ $checkLogDestination == "/var/log/messages" ]; then
                OK "4"
                    elif [ $checkLogDestination != "/var/log/messages" ]; then
                Notice "4" " saved in $checkLogDestination"
                    else
                CheckupErr "something went wrong"
                    fi
                else
        warn "11" "NO parameters setup"
                fi
            elif [ $i == "kern" ]; then
COUNTER=$((COUNTERC+2))
echo -n "5.1.1.${COUNTER} Checking if $i notifications are configured   "
                if [ $checkParameterExistence == "1" ]; then
                    if [ $checkLogDestination == "/var/log/kern.log" ]; then
                OK "4"
                    elif [ $checkLogDestination != "/var/log/kern.log" ]; then
                Notice "4" " saved in $checkLogDestination"
                    else
                CheckupErr "something went wrong"
                    fi
                else
        warn "11" "NO parameters setup"
                fi
            elif [ $i == "daemon" ]; then
COUNTER=$((COUNTERC+3))
echo -n "5.1.1.${COUNTER} Checking if $i notifications are configured   "
                if [ $checkParameterExistence == "1" ]; then
                    if [ $checkLogDestination == "/var/log/daemon.log" ]; then
                OK "4"
                    elif [ $checkLogDestination != "/var/log/daemon.log" ]; then
                Notice "4" " saved in $checkLogDestination"
                    else
                CheckupErr "something went wrong"
                    fi
                else
        warn "11" "NO parameters setup"
                fi
            elif [ $i == "syslog" ]; then
COUNTER=$((COUNTERC+4))
echo -n "5.1.1.${COUNTER} Checking if $i notifications are configured   "
                if [ $checkParameterExistence == "1" ]; then
                    if [ $checkLogDestination == "/var/log/syslog" ]; then
                OK "4"
                    elif [ $checkLogDestination != "/var/log/syslog" ]; then
                Notice "4" " saved in $checkLogDestination"
                    else
                CheckupErr "something went wrong"
                    fi
                else
        warn "11" "NO parameters setup"
                fi
            elif [ $i == "lpr,news,uucp,local0,local1" ]; then
COUNTER=$((COUNTERC+5))
echo -n "5.1.1.${COUNTER} Checking if $i notifications are configured   "
                if [ $checkParameterExistence == "1" ]; then
                    if [ $checkLogDestination == "/var/log/unused.log" ]; then
                OK "2"
                    elif [ $checkLogDestination != "/var/log/unused.log" ]; then
                Notice "2" " saved in $checkLogDestination"
                    else
                CheckupErr "something went wrong"
                    fi
                else
        warn "11" "NO parameters setup"
                fi
            else
            CheckupErr "something went wrong with check on what i is"
            fi
done

LogFiles=$(cat $syslogConf | grep ".log"| awk -F" " '{print $2}' | grep "/var/log" | awk -F"/log/" '{print $2}' |sort -u |tr "\n" " ")
LogCounter=$(cat $syslogConf | grep ".log"| awk -F" " '{print $2}' | grep "/var/log" | awk -F"/log/" '{print $2}' |sort -u | wc -l )
COUNTER="0"
while [ $COUNTER != $LogCounter ]; do
 for log in $LogFiles
     do
         let COUNTERE=COUNTER+1
echo -n "5.1.2.${COUNTERE} Checking permissions on $log file   "
         checkOwner=$(stat -c %u /var/log/$log)
            if [ "$checkOwner" != "0" ]; then
                if [ "$log" == "boot.log" ]; then
                    warn "11" "NOT owned by root."
                elif [ "$log" == "cron" ]; then
                    warn "11" "NOT owned by root."
                elif [ "$log" == "maillog" ]; then
                    warn "11" "NOT owned by root."
                elif [ "$log" == "messages" ]; then
                    warn "11" "NOT owned by root."
                elif [ "$log" == "secure" ]; then
                    warn "11" "NOT owned by root."
                elif [ "$log" == "spooler" ]; then
                    warn "11" "NOT owned by root."
                else
                    err "6" "NO SUCH LOG FILE: $log"
                fi
            elif [ "$checkOwner" == "0" ]; then
                if [ "$log" == "boot.log" ]; then
                    OK "5"
                elif [ "$log" == "cron" ]; then
                    OK "6"
                elif [ "$log" == "maillog" ]; then
                    OK "6"
                elif [ "$log" == "messages" ]; then
                    OK "5"
                elif [ "$log" == "secure" ]; then
                    OK "6"
                elif [ "$log" == "spooler" ]; then
                    OK "6"
                else
                    err "6" "NO SUCH LOG FILE: $log"
                fi
            else
                CheckupErr
            fi
COUNTER=$[$COUNTER +1]
     done
done
echo -n "5.1.3 Checking if sending logs to remote host is enabled   "
IsSendingEnabled=$(grep "^*.*[^I][^I]*@" $syslogConf |awk -F"@" '{print $2}' | sort -u | wc -l)
getRemoteHost=$(grep "^*.*[^I][^I]*@" $syslogConf  |awk -F"@" '{print $2}')
            if  [ $IsSendingEnabled -gt "0" ]; then
        Notice "4" "ENABLED"

            elif [ $IsSendingEnabled -eq "0" ]; then
        Notice "4" "DISABLED"
            else
        CheckupErr
            fi

echo -n "5.1.4.1 Check if accepting Logs from remote Hosts is enabled on running deamon "
checkProcess=$( ps ax | grep -i "syslogd -m" | grep -v "grep" | grep " -r" | wc -l)
            if [ $checkProcess -eq "1" ]; then
                Notice "1" "ENABLED"
            elif [ $checkProcess -eq "0" ]; then
                Notice "1" "DISABLED"
            else
                CheckupErr
            fi
echo -n "5.1.4.2 Check if accepting Log Files from remote Hosts is enabled in syslogd "
checkConfigFile=$( cat $syslogConf |grep " -r" | grep -v "grep\|^#" | wc -l)
            if [ $checkConfigFile -eq "1" ]; then
                Notice "1" "ENABLED"
            elif [ $checkConfigFile -eq "0" ]; then
                Notice "1" "DISABLED"
            else
                CheckupErr
            fi
        else
        warn "11" "Configuration file $syslogConf NOT FOUND"
        fi
    elif [ "$IsItRunning" == "stopped" ]; then
            warn "11" "not running"
    else
            CheckupErr "with check if service is running"
    fi
 elif [ "$IsSyslogEnabled" == "0" ]; then
    Notice "6" "OK - Not Installed"
 else
     CheckupErr
 fi
}

checkRsyslog() {
echo -n "5.2.1 Checking if rsyslog is installed "
pkg="rsyslog"
IsRsyslogInstalled=$(rpm -qa $pkg | grep "^$pkg" | wc -l)
    if [ $IsRsyslogInstalled -eq "1" ]; then
        OK "7"
echo -n "5.2.2.1 Checking if rsyslog is Activated "
IsItActivated=$( chkconfig --list rsyslog | wc -l)
        if [ $IsItActivated -gt "0" ]; then
getLevels=$( chkconfig --list rsyslog | tr "\t " "\n" | grep ":"  | grep "on" | awk -F":" '{print $1}' | tr "\n" " ")
            Notice "6" "on levels: $getLevels "
echo -n "5.2.2.2 Checking if syslog will interfere with rsyslog "
IsSyslogInstalled=$(rpm -qa syslog | grep "^syslog" | wc -l)
            if [ $IsSyslogInstalled -gt "0" ]; then
IsSyslogEnabled=$(chkconfig --list syslog | wc -l)
                if [ $IsSyslogEnabled -gt "0" ]; then
                    warn "11" "syslog ENABLED - please disable"
                elif [ $IsSyslogEnabled -eq "0" ]; then
                    OK "5"
                else
                    CheckupErr "with check if syslog is enabled"
                fi
           elif [ $IsSyslogInstalled -eq "0" ]; then
                Notice "5" "NOT installed"
           else
                CheckupErr "with check if syslog is installed"
           fi
echo -n "5.2.3.1 Checking if configuration file for rsyslog exists "
RsysConf="/etc/rsyslog.conf"
                if [ -e $RsysConf ]; then
# check configs here
                OK "4"
rsyslogParams="auth,user kern daemon syslog lpr,news,uucp,local0,local1"
COUNTERC="0"
                    for i in $rsyslogParams
                          do
                      checkLogDestination=$(grep ${i} $RsysConf| awk -F" " '{print $2}' )
                                  if [ $i == "auth,user" ]; then
                      COUNTER=$((COUNTERC+1))
                      echo -n "5.2.3.${COUNTER} Checking if $i notifications are configured "
                      checkParamExistence=$(grep ${i} $RsysConf | wc -l )
                                      if [ $checkParamExistence == "1" ]; then
                                            if [ $checkLogDestination == "/var/log/messages" ]; then
                                        OK "4"
                                            elif [ $checkLogDestination != "/var/log/messages" ]; then
                                        Notice "4" "saved in $checkLogDestination"
                                            else
                                        CheckupErr "something went wrong"
                                            fi
                                      else
                                        warn "11" "NO parameters setup"
                                      fi
                                  elif [ $i == "kern" ]; then
                      COUNTER=$((COUNTERC+2))
                      echo -n "5.2.3.${COUNTER} Checking if $i notifications are configured "
                                      if [ $checkParamExistence == "1" ]; then
                                            if [ $checkLogDestination == "/var/log/kern.log" ]; then
                                        OK "5"
                                            elif [ $checkLogDestination != "/var/log/kern.log" ]; then
                                        Notice "5" "saved in $checkLogDestination"
                                            else
                                        CheckupErr "something went wrong"
                                            fi
                                      else
                                        warn "11" "NO parameters setup"
                                      fi
                                  elif [ $i == "daemon" ]; then
                      COUNTER=$((COUNTERC+3))
                      echo -n "5.2.3.${COUNTER} Checking if $i notifications are configured "
                                      if [ $checkParamExistence == "1" ]; then
                                             if [ $checkLogDestination == "/var/log/daemon.log" ]; then
                                         OK "4"
                                             elif [ $checkLogDestination != "/var/log/daemon.log" ]; then
                                         Notice "4" " saved in $checkLogDestination"
                                             else
                                         CheckupErr "something went wrong"
                                             fi
                                      else
                                        warn "11" "NO parameters setup"
                                      fi
                                  elif [ $i == "syslog" ]; then
                      COUNTER=$((COUNTERC+4))
                      echo -n "5.2.3.${COUNTER} Checking if $i notifications are configured "
                                      if [ $checkParamExistence == "1" ]; then
                                             if [ $checkLogDestination == "/var/log/syslog" ]; then
                                         OK "4"
                                             elif [ $checkLogDestination != "/var/log/syslog" ]; then
                                         Notice "4" " saved in $checkLogDestination"
                                             else
                                         CheckupErr "something went wrong"
                                             fi
                                      else
                                        warn "11" "NO parameters setup"
                                      fi
                                  elif [ $i == "lpr,news,uucp,local0,local1" ]; then
                      COUNTER=$((COUNTERC+5))
                      echo -n "5.2.3.${COUNTER} Checking if $i notifications are configured "
                                      if [ $checkParamExistence == "1" ]; then
                                          if [ $checkLogDestination == "/var/log/unused.log" ]; then
                                        OK "1"
                                            elif [ $checkLogDestination != "/var/log/unused.log" ]; then
                                        Notice "1" " saved in $checkLogDestination"
                                            else
                                        CheckupErr "something went wrong"
                                            fi
                                      else
                                        warn "11" "NO parameters setup"
                                      fi
                                  else
                                  CheckupErr "something went wrong with check on what parameter we are in the for loop."
                                  fi
                    done
LogFiles=$(cat $RsysConf | grep ".log"| awk -F" " '{print $2}' | grep "/var/log" | awk -F"/log/" '{print $2}' |sort -u |tr "\n" " ")
LogCounter=$(cat $RsysConf | grep ".log"| awk -F" " '{print $2}' | grep "/var/log" | awk -F"/log/" '{print $2}' |sort -u | wc -l )
COUNTER="0"
while [ $COUNTER != $LogCounter ]; do
 for log in $LogFiles
     do
         let COUNTERE=COUNTER+1
echo -n "5.2.4.${COUNTERE} Checking permissions on /var/log/$log file "
         checkOwner=$(stat -c %u /var/log/$log)
            if [ "$checkOwner" != "0" ]; then
                warn "11" "NOT owned by root."
            elif [ "$checkOwner" == "0" ]; then
                OK "5"
            else
                CheckupErr
            fi
COUNTER=$[$COUNTER +1]
     done
done
                    echo -n "5.2.5 Checking if sending logs to remote host is enabled   "
                    IsSendingEnabled=$(grep "^*.*[^I][^I]*@" $RsysConf |awk -F"@" '{print $2}' | sort -u | wc -l)
                    getRemoteHost=$(grep "^*.*[^I][^I]*@" $RsysConf  |awk -F"@" '{print $2}')
                                if  [ $IsSendingEnabled -gt "0" ]; then
                            Notice "4" "ENABLED"
                                elif [ $IsSendingEnabled -eq "0" ]; then
                            warn "11" "DISABLED"
                                else
                            CheckupErr
                                fi
                    echo -n "5.2.6.1 Check if Module for accepting Logs from remote Hosts is loaded"
                    IsNetworkModuleLoaded=$(grep "ModLoad imtcp" $RsysConf | grep -v "^#" | wc -l)
                        if [ "$IsNetworkModuleLoaded" == "1" ] ; then
                            OK "3" "OK"
                        elif [ "$IsNetworkModuleLoaded" == "0" ] ; then
                            err "3" "ERROR: Module Disabled"
                        else
                            CheckupErr "with check if Module imtcp is enabled"
                        fi
                    echo -n "5.2.6.2 Check if rsyslogd is instructed to listen on tcp port"
                    IsListeningEnabled=$(grep "InputTCPServerRun " $RsysConf | grep -v "^#" | wc -l)
                        if [ "$IsListeningEnabled" == "1" ]; then
                            getPort=$(grep "InputTCPServerRun " $RsysConf | grep -v "^#" |awk -F" " '{print $2}')
                            OK "4" "OK - listening on port $getPort"
                        elif [ "$IsListeningEnabled" == "0" ]; then
                            err "4" "ERROR: Listening Disabled"
                        else
                            CheckupErr "with check if listening is enabled"
                        fi
                else
                    err "4" "MISSING"
                fi

        elif [ $IsItActivated -eq "0" ]; then
            warn "11" "NOT enabled at boot"
        else
            CheckupErr "with check if rsyslog is enabled at boot"
        fi
    elif [ $IsRsyslogInstalled -eq "0" ]; then
        Notice "7" "Not Installed"
    else
        CheckupErr "with check if rsyslog is installed"
    fi
}

checkAuditd() {
AuditRules="/etc/audit/audit.rules"
Aconf="/etc/audit/auditd.conf"

echo -n "5.3.1a Check if auditd is installed."
IsAuditInstalled=$(rpm -qa audit | grep "^audit" | wc -l)
if [ "$IsAuditInstalled" == "1" ]; then
    OK "7" "OK"
    echo -n "5.3.1b Check if auditd is enabled at boot."
    IsAuditEnabled=$(chkconfig --list auditd | grep "on" | wc -l)
    getLevels=$( chkconfig --list auditd | tr "\t " "\n" | grep ":"  | grep "on" | awk -F":" '{print $1}' | tr "\n" " ")
        if [ "$IsAuditEnabled" == "1" ]; then
                Notice "6" "OK - enabled on levels: $getLevels"
    elif [ "$IsAuditEnabled" == "0" ]; then
        warn "11" "Installed but not enabled at boo"
    else
        CheckupErr "with check if audit is enabled at boot."
    fi
    echo -n "5.3.2.1 Check Audit Log Storage Size"
    IsSizeEnabled=$(grep "max_log_file " $Aconf | grep -v "^#" | wc -l)
    if [ "$IsSizeEnabled"  == "1" ]; then
                checkSize=$(grep "max_log_file " $Aconf | grep -v "^#" | awk -F"= " '{print $2}')
        if [ "$checkSize" -gt "0" ]; then
            Notice "7" "set to $checkSize MB"
        elif [ "$checkSize" -eq "0" ]; then
            err "7" "Size is set to 0."
        else
                        CheckupErr "with check for log size in auditd"
        fi
    elif [ "$IsSizeEnabled"  == "0" ]; then
        err "7" "Size NOT set"
    else
        CheckupErr "with check for size of the log"
    fi

CHECKUSERGROUPINFO() {
echo -n "5.3.5 Check if we record events that modify User/Group information."
userGroupRulesCount=$(grep "identity$" $AuditRules | grep -v "^#"| wc -l)
if [ "$userGroupRulesCount" == "0" ]; then
    err "3" "No RULES CONFIGURED"
elif [ "$userGroupRulesCount" == "1" ]; then
# check if we have correct rules:

        echo -n "5.3.5a Check if we monitor changes to group file."
        groupCheck=$(grep "\-w /etc/group \-p wa \-k identiy" $AuditRules | grep -v "^#"| wc -l)
        if [ "$groupCheck" == "0" ]; then
        err "5" "RULE NOT SET"
    elif [ "$groupCheck" == "1" ]; then
        OK "5"
    else
        CheckupErr "something went wrong"
    fi
    echo -n "5.3.5b Check if we monitor changes to passwd file."
    passwdCheck=$(grep "\-w /etc/passwd \-p wa \-k identity" $AuditRules | grep -v "^#"| wc -l)
    if [ "$passwdCheck" == "0" ]; then
        err "5" "RULE NOT SET"
    elif [ "$passwdCheck" == "1" ]; then
        OK "5"
    else
        CheckupErr "something went wrong"
    fi
    echo -n "5.3.5c Check if we monitor changes to gshadow file."
    gshadowCheck=$(grep "\-w /etc/gshadow \-p wa \-k identity" $AuditRules | grep -v "^#"| wc -l)
    if [ "$gshadowCheck" == "0" ]; then
        err "5" "RULE NOT SET"
    elif [ "$gshadowCheck" == "1" ]; then
        OK "5"
    else
        CheckupErr "something went wrong"
    fi

    echo -n "5.3.5d Check if we monitor changes to PAM configuration file."
    PAMcheck=$(grep "\-w /etc/security/opasswd \-p wa \-k identity" $AuditRules | grep -v "^#"| wc -l)
    if [ "$PAMcheck" == "0" ]; then
        err "5" "RULE NOT SET"
    elif [ "$PAMcheck" == "1" ]; then
        OK "5"
    else
        CheckupErr "something went wrong"
    fi
else
    CheckupErr "something went wrong"
fi
}

CHECKLOCALTIME() {
checkLine5=$(grep "\-w /etc/localtime \-p wa \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkLine5" == "1" ]; then
        OK "5" "rule5 exists"
elif [ "$checkLine5" == "0" ]; then
        warn "11" "RULE NOT SET"
else
        CheckupErr "with check for existence of rule5"
fi
}

CHECKOSFILE() {
checkIssue=$(grep "\-w /etc/issue \-p wa \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkIssue" == "0" ]; then
        err "5" "RULE NOT SET"
elif [ "$checkIssue" == "1" ]; then
        OK "5"
else
        CheckupErr
fi
}

CHECKISSUENETFILE() {
checkIssue2=$(grep "\-w /etc/issue.net \-p wa \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkIssue2" == "0" ]; then
        err "5" "RULE NOT SET"
elif [ "$checkIssue2" == "1" ]; then
        OK "5"
else
        CheckupErr
fi
}

CHECKHOSTFILE() {
checkHostsFile=$(grep "\-w /etc/hosts \-p wa \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkHostsFile" == "0" ]; then
        err "5" "RULE NOT SET"
elif [ "$checkHostsFile" == "1" ]; then
        OK "5"
else
        CheckupErr
fi
}

CHECKNETWORKFILE() {
checkNetworkFile=$(grep "\-w /etc/sysconfig/network \-p wa \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkNetworkFile" == "0"]; then
        err "5" "RULE NOT SET"
elif [ "$checkNetworkFile" == "1"]; then
        OK "5"
else
        CheckupErr
fi
}

CHECKMAC() {
echo -n "5.3.7 Check if we record events that modify system's Mandatory Access Controls."
checkselinux=$(grep "\-w /etc/selinux/ \-p wa \-k MAC-policy" $AuditRules | grep -v "^#"| wc -l)
if [ "$checkselinux" == "1" ]; then
        OK "2"
elif [ "$checkselinux" == "0" ]; then
        err "2" "RULE NOT SET"
else
        CheckupErr
fi
}

CHECKLOGINEVENTS() {
echo -n "5.3.8 Check if we collect Login and Logout Events."
isLoginEventsEnabled=$(grep "logins$\|session$" $AuditRules| grep -v "^#"| wc -l)
if [ "$isLoginEventsEnabled" == "0" ]; then
        err "5" "DISABLED"
elif [ "$isLoginEventsEnabled" -gt "0" ]; then
        OK "5"
        echo -n "5.3.8a Check if monitoring for Faillog is enabled"
        monitoringFaillog=$(grep "\-w /var/log/faillog \-p wa \-k logins" $AuditRules | grep -v "^#"| wc -l )
        if [ "$monitoringFaillog" == "0" ]; then
                err "5" "RULE NOT SET"
        elif [ "$monitoringFaillog" == "1" ]; then
                OK "5"
        else
                CheckupErr
        fi
        echo -n "5.3.8b Check if monitoring for lastlog is enabled"
        monitoringLastlog=$(grep "\-w /var/log/lastlog \-p wa \-k logins" $AuditRules | grep -v "^#"| wc -l )
        if [ "$monitoringLastlog" == "0" ]; then
                err "5" "RULE NOT SET"
        elif [ "$monitoringLastlog" == "1" ]; then
                OK "5"
        else
                CheckupErr
        fi
        echo -n "5.3.8c Check if monitoring for tallylog is enabled"
        monitoringTallylog=$( grep "\-w /var/log/tallylog \-p wa \-k logins" $AuditRules | grep -v "^#"| wc -l)
        if [ "$monitoringTallylog" == "0" ]; then
                err "5" "RULE NOT SET"
        elif [ "$monitoringTallylog" == "1" ]; then
                OK "5"
        else
                CheckupErr
        fi
        echo -n "5.3.8d Check if monitoring for btmp log is enabled"
        monitoringBTMP=$(grep "\-w /var/log/btmp \-p wa \-k session" $AuditRules | grep -v "^#"| wc -l )
        if [ "$monitoringBTMP" == "0" ]; then
                err "5" "RULE NOT SET"
        elif [ "$monitoringBTMP" == "1" ]; then
                OK "5"
        else
                CheckupErr
        fi
else
        CheckupErr
fi
}

CHECKSESSIONEVENTS() {
echo -n "5.3.9 Check if we collect session initiation information."
isSessionMonitoringEnabled=$(grep "session$" $AuditRules| grep "utmp\|wtmp" | grep -v "^#"| wc -l)
if [ "$isSessionMonitoringEnabled" == "0" ]; then
        err "4" "DISABLED"
elif [ "$isSessionMonitoringEnabled" -gt "0" ]; then
        OK "4"
                echo -n "5.3.9a Check if we monitor session events to currently logged in users."
                checkutmp=$(grep "\-w /var/run/utmp \-p wa \-k session" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkutmp" == "0" ]; then
                        err "3" "RULE NOT SET"
                elif [ "$checkutmp" == "1" ]; then
                        OK "3"
                else
                        CheckupErr
                fi
                echo -n "5.3.9b Check if we monitor logins, loouts, shutdown and reboot events."
                checkwtmp=$(grep "\-w /var/log/wtmp \-p wa \-k session" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkwtmp" == "0" ]; then
                        err "3" "RULE NOT SET"
                elif [ "$checkwtmp" == "1" ]; then
                        OK "3"
                else
                        CheckupErr
                fi
else
        CheckupErr
fi
}

    echo -n "5.3.2.2a Check if email action is set when OS is STARTING to get low on space."
    isActionEnabled=$(grep "^space_left_action" $Aconf | grep -v "^#" | wc -l)
    if [ "$isActionEnabled" -eq "1" ]; then
        checkAction=$(grep "^space_left_action" $Aconf| grep -v "^#"| awk -F"= " '{print $2}')
        if [ "$checkAction" == "email" ]; then
            OK "2" "OK"
        elif [ "$checkAction" != "email" ]; then
            warn "11" "set to $checkAction"
        else
            CheckupErr "with check for what action is set"
        fi
        echo -n "5.3.2.2b Check if root is set as email recipient"
        checkRecipient=$(grep "^action_mail_acct" $Aconf | grep -v "^#"| awk -F"= " '{print $2}' )
        if [ "$checkRecipient" == "root" ]; then
            OK "5" "OK"
        elif [ "$checkRecipient" != "root" ]; then
            warn "11" "set to $checkRecipient"
        else
            CheckupErr "with check for email recipient"
        fi
        echo -n "5.3.2.2c Check if system is HALTED when disk is low on space"
        CheckLowSpaceAction=$(grep "^admin_space_left_action" $Aconf | grep -v "^#"| awk -F"= " '{print $2}' )
        if [ "$CheckLowSpaceAction" == "halt" ]; then
            OK "4" "OK"
        elif [ "$CheckLowSpaceAction" != "halt" ]; then
            warn "11" "set to $CheckLowSpaceAction"
        else
            CheckupErr "with check for action when disk is low on space"
        fi
        echo -n "5.3.2.3 Check if old audit logs are retained."
        RotateLogAction=$(grep "^max_log_file_action" $Aconf | grep -v "^#"| awk -F"= " '{print $2}')
        if [ "$RotateLogAction" == "keep_logs" ]; then
            OK "6" "OK"
        elif [ "$RotateLogAction" != "keep_logs" ]; then
            warn "11" "set to $RotateLogAction"
        else
            CheckupErr "with check for action on rotating logs"
        fi
        echo -n "5.3.3 Check if Auditing for processes that start prior to auditd is enabled"
        checkPriorProcesses=$(grep "audit=1" $Aconf | grep -v "^#"| wc -l)
        if [ "$checkPriorProcesses" -eq "0" ]; then
                        err "2" "DISABLED"
        elif [ "$checkPriorProcesses" -eq "1" ]; then
            OK "2" "OK"
        else
            CheckupErr "with check for processes starting prior to auditd"
        fi
        echo -n "5.3.4 Check if we Record events that modify Date & Time information "
        # check first if we're on 64bit or 32bit machine
        #AuditRules="/etc/audit/audit.rules"
        checkArch=$(uname -m)
        if [ "$checkArch" == "x86_64" ]; then
                        OK "3"
                        Notice "11" "you're on 64bit machine"
                        # CHECKS FOR 64BIT MACHINE
                        echo -n "5.3.4.a Check if there are any rules configured "
            timeRulesCount=$(grep "time-change$" $AuditRules | grep -v "^#"| wc -l)
            if [ "$timeRulesCount" == "0" ]; then
                                err "5" "There are no rules setup."
            elif [ "$timeRulesCount" -gt "0" ]; then
                                OK "5" "there are $timeRulesCount rules"
                                echo -n "5.3.4.aa Check if we record adjtimex, settimeofday system calls."
                checkLine1=$(grep "\-a always,exit \-F arch=b64 \-S adjtimex \-S settimeofday \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkLine1" == "1" ]; then
                                        OK "3" "rule1 exists"
                elif [ "$checkLine1" == "0" ]; then
                                        warn "11" "RULE NOT SET"
                else
                                        CheckupErr "with check for existence of rule1"
                fi
                echo -n "5.3.4.ab Check if we record adjtimex, settimeofday, stime system calls."
                checkLine2=$(grep "\-a always,exit \-F arch=b32 \-S adjtimex \-S settimeofday \-S stime \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkLine2" == "1" ]; then
                                        OK "3" "rule2 exists"
                elif [ "$checkLine2" == "0" ]; then
                                        warn "11" "RULE NOT SET"
                else
                                        CheckupErr "with check for existence of rule2"
                fi
                echo -n "5.3.4.ac Check if we record clock_settime system calls for arch=b64"
                                checkLine3=$(grep "\-a always,exit \-F arch=b64 \-S clock_settime \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkLine3" == "1" ]; then
                                        OK "3" "rule3 exists"
                                elif [ "$checkLine3" == "0" ]; then
                                        warn "11" "RULE NOT SET"
                else
                                        CheckupErr "with check for existence of rule3"
                fi
                echo -n "5.3.4.ad Check if we record clock_settime system calls for arch=b32"
                checkLine4=$(grep "\-a always,exit \-F arch=b32 \-S clock_settime \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
                if [ "$checkLine4" == "1" ]; then
                                        OK "3" "rule4 exists"
                elif [ "$checkLine4" == "0" ]; then
                                        warn "11" "RULE NOT SET"
                else
                                        CheckupErro "with check for existence of rule4"
                fi
                echo -n "5.3.4.ae Check if we record changes to /etc/localtime"
                                CHECKLOCALTIME
            else
                                CheckupErr "with check if we have any rules for time changes for 64bit machine"
            fi
                        CHECKUSERGROUPINFO
                        echo -n "5.3.6 Check if we record events that modify system's network environment."
                        checkSystemLocale=$(grep "system-locale$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$checkSystemLocale" == "0" ]; then
                                err "2" "NO RULES CONFIGURED."
                        elif [ "$checkSystemLocale" -gt "0" ]; then
                                OK "2"
                                echo -n "5.3.6a Check if we record changes to hostname, domainname for arch=b64"
                                checkHostDomain64=$(grep "\-a exit,always \-F arch=b64 \-S sethostname \-S setdomainname \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkHostDomain64" == "0" ]; then
                                        err "3" "RULE NOT SET"
                                elif [ "$checkHostDomain64" == "1" ]; then
                                        OK "3"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.6b Check if we record changes to hostname, domainname for arch=b32"
                                checkHostDomain32=$(grep "\-a exit,always \-F arch=b32 \-S sethostname \-S setdomainname \-k system\-locale" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkHostDomain32" == "0" ]; then
                                        err "3" "RULE NOT SET"
                                elif [ "$checkHostDomain32" == "1" ]; then
                                        OK "3"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.6c Check if we record changes to /etc/issue file."
                                CHECKOSFILE
                                echo -n "5.3.6d Check if we record changes to /etc/issues.net file."
                                CHECKISSUENETFILE
                                echo -n "5.3.6e Check if we record changes to hosts file."
                                CHECKHOSTFILE
                                echo -n "5.3.6f Check if we record changes to network file."
                                CHECKNETWORKFILE
                        else
                                CheckupErr
                        fi
                        CHECKMAC                        # 5.3.7
                        CHECKLOGINEVENTS        # 5.3.8
                        CHECKSESSIONEVENTS      # 5.3.9
                        echo -n "5.3.10 Check if we collect information about permission modification events."
                        isCollectingEventsEnabled=$(grep "perm_mod$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$isCollectingEventsEnabled" == "0" ]; then
                                err "2" "DISABLED"
                        elif [ "$isCollectingEventsEnabled" -gt "0" ]; then
                                OK "2"
                                # checks for 64 bit machine
                                echo -n "5.3.10a Check if we monitor chmod, fchmod, fchmodat on arch=b64."
                                checkSysCallsb64=$(grep "\-a always,exit \-F arch=b64 \-S chmod \-S fchmod \-S fchmodat \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCallsb64" == "0" ]; then
                                        err "3" "RULE NOT SET"
                                elif [ "$checkSysCallsb64" == "1" ]; then
                                        OK "3"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10b Check if we monitor chmod, fchmod, fchmodat on arch=b32."
                                checkSysCalls2b32=$(grep "\-a always,exit \-F arch=b32 \-S chmod \-S fchmod \-S fchmodat \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCalls2b32" == "0" ]; then
                                        err "3" "RULE NOT SET"
                                elif [ "$checkSysCalls2b32" == "1" ]; then
                                        OK "3"
                                else
                                CheckupErr
                                fi
                                echo -n "5.3.10c Check if we monitor chown, fchown, fchownat, lchown on arch=b64."
                                checkSysCalls3b64=$(grep "\-a always,exit \-F arch=b64 \-S chown \-S fchown \-S fchownat \-S lchown \-F auid\>=500 \-F auid\!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCalls3b64" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCalls3b64" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10d Check if we monitor chown, fchown, fchownat, lchown on arch=b32."
                                checkSysCall4b32=$( grep "\-a always,exit \-F arch=b32 \-S chown \-S fchown \-S fchownat \-S lchown \-F auid\>=500 \-F auid\!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCall4b32" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCall4b32" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10e Check if we monitor changes to extended file attributes on arch=b64."
                                checkSysCall5b64=$(grep "\-a always,exit \-F arch=b64 \-S setxattr \-S lsetxattr \-S fsetxattr \-S removexattr \-S lremovexattr \-S fremovexattr \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCall5b64" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCall5b64" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10f Check if we monitor changes to extended file attributes on arch=b32."
                                checkSysCall6b32=$(grep "\-a always,exit \-F arch=b32 \-S setxattr \-S lsetxattr \-S fsetxattr \-S removexattr \-S lremovexattr \-S fremovexattr \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCall6b32" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCall6b32" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                        else
                                CheckupErr
                        fi
                        echo -n "5.3.11 Check if we monitor unsuccessful attempts to access files."
                        isCheck5311enabled=$(grep "access$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$isCheck5311enabled" == "0" ]; then
                                err "3" "DISABLED"
                        elif [ "$isCheck5311enabled" -gt "0" ]; then
                                OK "3"
                                echo -n "5.3.11a Check for system calls with returned permission denied on arch=b64"
                                checkAccessRule1=$(grep "\-a always,exit \-F arch=b64 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=\-EACCES \-F auid>=500 \-F auid!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkAccessRule1" == "0" ]; then
                                        err "1" "RULE NOT SET"
                                elif [ "$checkAccessRule1" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.11b Check for system calls with returned permission denied on arch=b32"
                                checkAccessRule2=$(grep "\-a always,exit \-F arch=b32 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=\-EACCES \-F auid>=500 \-F auid!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkAccessRule2" == "0" ]; then
                                        err "1" "RULE NOT SET"
                                elif [ "$checkAccessRule2" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.11c Check for system calls with returned permanent error on arch=b64"
                                checkAccessRule3=$(grep "\-a always,exit \-F arch=b64 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=-EPERM \-F auid>=500 \-F audi!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l )
                                if [ "$checkAccessRule3" == "0" ]; then
                                        err "1" "RULE NOT SET"
                                elif [ "$checkAccessRule3" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.11d Check for system calls with returned permanent error on arch=b32"
                                checkAccessRule4=$(grep "\-a always,exit \-F arch=b32 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=-EPERM \-F auid>=500 \-F audi!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l )
                                if [ "$checkAccessRule4" == "0" ]; then
                                        error "1" "RULE NOT SET"
                                elif [ "$checkAccessRule4" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                        else
                                CheckupErr
                        fi

            echo -n "5.3.12 Check if we monitor use of privileged commands"
            checkPrivileged=$(grep "privileged$" $AuditRules | grep -v "^#"| wc -l)
            # find all files with setuid/setgid:
            listPrivilegedPrograms=$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f)
            privilegedCount=$(echo "${listPrivilegedPrograms}" | wc -l)
            notMonitored="$(pwd)/not-monitored.tmp"
            monitored="$(pwd)/ok-list.tmp"
            touch ${notMonitored} ${monitored}

            for i in ${listPrivilegedPrograms}
             do
                IsMonitored=$(grep "$i" $AuditRules | wc -l)
                # if program is monitored add it to ok-list
                # if not then add it to NO-list
                if [ "$IsMonitored" -eq "0" ]; then
                    echo $i >>${notMonitored}
                else
                    echo $i >>${monitored}
                fi
             done
                # check the status of ok-list file:
                notMonitoredCount=$(wc -l ${notMonitored} | cut -d" " -f1)
                monitoredCount=$(wc -l ${monitored} )
                 # check if file has more than 0 bytes in size
                if [[ -s ${monitored} ]] ; then
                    # check the count of not monitored and complain about them
                    if [ "${notMonitoredCount}" -eq "0" ]; then
                        OK "5" "We are monitoring ${monitoredCount} privileged programs."
                    else
                        warn "11" "We have ${notMonitoredCount} NOT monitored privileged programs out of ${privilegedCount} ."
                    fi
                else
                    err "5" "We are monitoring 0 out of ${privilegedCount} privileged programs."
                fi
               rm -rf ${notMonitored} ${monitored}

            echo -n "5.3.13 Check if we monitor successful file system mounts." # 64 bit system
            # check if the option doesn't have '#' at the start
            isMountMonitored=$(grep "mounts" $AuditRules | grep -v "^#"| wc -l)
            if [ "${isMountMonitored}" -eq "1" ]; then
                monitoredArch=$(grep "mounts" $AuditRules  | grep -v "^#" | awk -F"arch=b" '{print $2}' | cut -d" " -f 1)
                warn "11" "ONLY ${monitoredArch} architecture is monitored"
            elif [ "${isMountMonitored}" -eq "2" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"
            fi

            echo -n "5.3.14 Check if we monitor file deletion events." # 64 bit system
            isDeletionMonitored=$(grep "delete" $AuditRules  | grep -v "^#" | wc -l)
            if [ "${isDeletionMonitored}" -eq "1" ]; then
                delMonArch=$(grep "delete" $AuditRules  | grep -v "^#" | awk -F"arch=b" '{print $2}' | cut -d" " -f 1)
                warn "11" "ONLY ${delMonArch} architecture is monitored"
            elif [ "${isDeletionMonitored}" -eq "2" ]; then
                OK "5"
            else
                err "5" "NOT MONITORED"
            fi
            
            
            echo -n "5.3.15 Check if we monitor changes to sudoers scope."
            isSudoMonitored=$(grep "sudoers" $AuditRules  | grep -v "^#" | wc -l)
            if [ "${isSudoMonitored}" -eq "1" ]; then
                OK "5"
            else
                err "5" "NOT MONITORED"
            fi
            
            
            echo -n "5.3.16 Check if we monitor system administrator actions."
            sudoersChanges=$(grep "\-w /var/log/sudo.log \-p wa \-k" $AuditRules  | grep -v "^#" | wc -l)
            if [ "${sudoersChanges}" -eq "1" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"
            fi
            
            
            echo -n "5.3.17 Check if we monitor kernel module loading and unloading."
            kernelModulesMonitored=$(grep "\-w /sbin/insmod \|\-w /sbin/rmmod \|\-w /sbin/modprobe \|\-S init_module" $AuditRules | grep -v "^#" | wc -l)
            if [ "${kernelModulesMonitored}" -lt "4" ] && [ "${kernelModulesMonitored}" -ge "1" ] ; then
                getModules=$(grep "\-w /sbin/insmod \|\-w /sbin/rmmod \|\-w /sbin/modprobe \|\-S init_module" $AuditRules | egrep -v "^#" | grep -oh "init_module\|delete_module\|insmod\|rmmod\|modprobe" | tr "\n" " ")
                warn "11" "Only ${getModules} are monitored."
            elif [ "${kernelModulesMonitored}" -eq "4" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"    
            fi

            echo -n "5.3.18 Check if audit configuration is immutable."
            ImmuneStatus=$(grep "^-e 2" $AuditRules | wc -l)
            if [ "${ImmuneStatus}" -eq "1" ]; then
                OK "5"
            else
                err "5" "DISABLED"
            fi
            

                elif [ "$checkArch" == "sparc" ]; then
                        warn "11" "this check won't work since you're on sparc"
                elif [ "$checkArch" == "i686" ]; then
                        OK "3"
                        Notice "11" "you're on 32bit machine"
                        echo -n "5.3.4.a Check if there are any rules configured "
                        timeRulesCount=$(grep "time-change$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$timeRulesCount" == "0" ]; then
                                err "5" "There are no rules setup."
                        elif [ "$timeRulesCount" -gt "0" ]; then
                                OK "5" "there are $timeRulesCount rules"
                                echo -n "5.3.4.aa Check if we record adjtimex, settimeofday, stime system calls."
                                checkLine1=$(grep "\-a always,exit \-F arch=b32 \-S adjtimex \-S settimeofday \-S stime \-l time\-change" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkLine1" == "1" ]; then
                                        OK "3" "rule1 exists"
                                elif [ "$checkLine1" == "0" ]; then
                                        warn "11" "RULE NOT SET"
                                else
                                        CheckupErr "with check for existence of rule1"
                                fi
                                echo -n "5.3.4.ab Check if we record clock_settime system calls."
                                checkLine2=$(grep "\-a always,exit \-F arch=b32 \-S clock_settime \-k time\-change" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkLine2" == "1" ]; then
                                        OK "5" "RULE NOT SET"
                                elif [ "$checkLine2" == "0" ]; then
                                        warn "11" "rule doesn't exist"
                                else
                                        CheckupErr "with check for existence of rule2"
                                fi
                                echo -n "5.3.4.ac Check if we record changes to /etc/localtime"
                                CHECKLOCALTIME
                        else
                                CheckupErr "with check if we have any rules setup on 32bit machine"
                        fi
                        CHECKUSERGROUPINFO
                        echo -n "5.3.6 Check if we record events that modify system's network environment."
                        checkSystemLocale=$(grep "system-locale$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$checkSystemLocale" == "0" ]; then
                                err "2" "NO RULES CONFIGURED"
                        elif [ "$checkSystemLocale" -gt "0" ]; then
                                OK "2"
                                echo -n "5.3.6a Check if we record changes to hostname, domainname for arch=b32"
                                checkHostDomain32=$(grep "\-a exit,always \-F arch=b32 \-S sethostname \-S setdomainname \-k system-locale" $AuditRules| grep -v "^#"| wc -l)
                                if [ "$checkHostDomain32" == "1" ]; then
                                        OK "2"
                                elif [ "$checkHostDomain32" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.6b Check if we record changes to /etc/issue file."
                                CHECKOSFILE
                                echo -n "5.3.6c Check if we record changes to /etc/issues.net file."
                                CHECKISSUENETFILE
                                echo -n "5.3.6d Check if we record changes to hosts file."
                                CHECKHOSTFILE
                                echo -n "5.3.6e Check if we record changes to network file."
                                CHECKNETWORKFILE
                        else
                                CheckupErr
                        fi
                        CHECKMAC                        # 5.3.7
                        CHECKLOGINEVENTS        # 5.3.8
                        CHECKSESSIONEVENTS      # 5.3.9
                        echo -n "5.3.10 Check if we collect information about permission modification events."
                        isCollectingEventsEnabled=$(grep "perm_mod$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$isCollectingEventsEnabled" == "0" ]; then
                                err "2" "DISABLED"
                        elif [ "$isCollectingEventsEnabled" -gt "0" ]; then
                                OK "2"
                                # checks for 32 bit machine
                                echo -n "5.3.10a Check if we monitor chmod, fchmod, fchmodat on arch=b32."
                                checkSysCalls2b32=$(grep "\-a always,exit \-F arch=b32 \-S chmod \-S fchmod \-S fchmodat \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCalls2b32" == "0" ]; then
                                        err "3" "RULE NOT SET"
                                elif [ "$checkSysCalls2b32" == "1" ]; then
                                        OK "3"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10b Check if we monitor chown, fchown, fchownat, lchown on arch=b32."
                                checkSysCall4b32=$( grep "\-a always,exit \-F arch=b32 \-S chown \-S fchown \-S fchownat \-S lchown \-F auid\>=500 \-F auid\!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCall4b32" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCall4b32" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.10c Check if we monitor changes to extended file attributes on arch=b32."
                                checkSysCall6b32=$(grep "\-a always,exit \-F arch=b32 \-S setxattr \-S lsetxattr \-S fsetxattr \-S removexattr \-S lremovexattr \-S fremovexattr \-F auid\>=500 \-F auid!=4294967295 \-k perm_mod" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkSysCall6b32" == "0" ]; then
                                        err "2" "RULE NOT SET"
                                elif [ "$checkSysCall6b32" == "1" ]; then
                                        OK "2"
                                else
                                        CheckupErr
                                fi
                        else
                                CheckupErr
                        fi
                        echo -n "5.3.11 Check if we monitor unsuccessful attempts to access files."
                        isCheck5311enabled=$(grep "access$" $AuditRules | grep -v "^#"| wc -l)
                        if [ "$isCheck5311enabled" == "0" ]; then
                                err "3" "NO SETUP RULES"
                        elif [ "$isCheck5311enabled" -gt "0" ]; then
                                OK "3"
                                echo -n "5.3.11a Check for system calls with returned permission denied on arch=b32"
                                checkAccessRule2=$(grep "\-a always,exit \-F arch=b32 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=\-EACCES \-F auid>=500 \-F auid!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l)
                                if [ "$checkAccessRule2" == "0" ]; then
                                        err "1" "RULE NOT SET"
                                elif [ "$checkAccessRule2" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                                echo -n "5.3.11b Check for system calls with returned permanent error on arch=b32"
                                checkAccessRule4=$(grep "\-a always,exit \-F arch=b32 \-S creat \-S open \-S openat \-S truncate \-S ftruncate \-F exit=-EPERM \-F auid>=500 \-F audi!=4294967295 \-k access" $AuditRules | grep -v "^#"| wc -l )
                                if [ "$checkAccessRule4" == "0" ]; then
                                        err "1" "RULE NOT SET"
                                elif [ "$checkAccessRule4" == "1" ]; then
                                        OK "1"
                                else
                                        CheckupErr
                                fi
                        else
                                CheckupErr
                        fi

            echo -n "5.3.12 Check if we monitor use of privileged commands"
            checkPrivileged=$(grep "privileged$" $AuditRules | grep -v "^#"| wc -l)
            # find all files with setuid/setgid:
            listPrivilegedPrograms=$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f)
            privilegedCount=$(echo "${listPrivilegedPrograms}" | wc -l)
            notMonitored="$(pwd)/not-monitored.tmp"
            monitored="$(pwd)/ok-list.tmp"
            touch ${notMonitored} ${monitored}

            for i in ${listPrivilegedPrograms}
             do
                IsMonitored=$(grep "$i" $AuditRules | grep -v "^#"| wc -l)
                # if program is monitored add it to ok-list
                # if not then add it to NO-list
                if [ "$IsMonitored" -eq "0" ]; then
                    echo $i >>${notMonitored}
                else
                    echo $i >>${monitored}
                fi
             done
            # check the status of ok-list file:
            notMonitoredCount=$(wc -l ${notMonitored} | cut -d" " -f1)
            monitoredCount=$(wc -l ${monitored} )
            # check if file has more than 0 bytes in size
            if [[ -s ${monitored} ]] ; then
            # check the count of not monitored and complain about them
                if [ "${notMonitoredCount}" -eq "0" ]; then
                    OK "5" "We are monitoring ${monitoredCount} privileged programs."
                else
                    warn "11" "We have ${notMonitoredCount} NOT monitored privileged programs out of ${privilegedCount} ."
                fi
            else
                err "5" "We are monitoring 0 out of ${privilegedCount} privileged programs."
            fi
            rm -rf ${notMonitored} ${monitored}

            echo -n "5.3.13 Check if we monitor successful file system mounts." # 32 bit system
            isMountMonitored=$(grep "mounts" $AuditRules | grep -v "^#"| wc -l)
            if [ "${isMountMonitored}" -ge "1" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"
            fi

            echo -n "5.3.14 Check if we monitor file deletion events."
            isDeletionMonitored=$(grep "delete" $AuditRules | grep -v "^#" | wc -l)
            if [ "${isDeletionMonitored}" -eq "1" ]; then
                OK "5"
            else
                err "5" "NOT MONITORED"
            fi

            echo -n "5.3.15 Check if we monitor changes to sudoers scope."
            isSudoMonitored=$(grep "sudoers" $AuditRules | grep -v "^#" | wc -l)
            if [ "${isSudoMonitored}" -eq "1" ]; then
                OK "5"
            else
                err "5" "NOT MONITORED"
            fi

            echo -n "5.3.16 Check if we monitor system administrator actions."
            sudoersChanges=$(grep "\-w /var/log/sudo.log \-p wa \-k" $AuditRules  | grep -v "^#" | wc -l)
            if [ "${sudoersChanges}" -eq "1" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"
            fi

            echo -n "5.3.17 Check if we monitor kernel module loading and unloading."
            kernelModulesMonitored=$(grep "\-w /sbin/insmod \|\-w /sbin/rmmod \|\-w /sbin/modprobe \|\-S init_module" $AuditRules | grep -v "^#" | wc -l)
            if [ "${kernelModulesMonitored}" -lt "4" ] && [ "${kernelModulesMonitored}" -ge "1" ] ; then
                getModules=$(grep "\-w /sbin/insmod \|\-w /sbin/rmmod \|\-w /sbin/modprobe \|\-S init_module" $AuditRules | egrep -v "^#" | grep -oh "init_module\|delete_module\|insmod\|rmmod\|modprobe" | tr "\n" " ")
                warn "11" "Only ${getModules} are monitored."
            elif [ "${kernelModulesMonitored}" -eq "4" ]; then
                OK "4"
            else
                err "4" "NOT MONITORED"    
            fi

            echo -n "5.3.18 Check if audit configuration is immutable."
            ImmuneStatus=$(grep "^-e 2" $AuditRules | wc -l)
            if [ "${ImmuneStatus}" -eq "1" ]; then
                OK "5"
            else
                err "5" "DISABLED"
            fi
                else
                        CheckupErr "with check if you are on 64 or 32 bit machine"
                fi
        elif [ "$isActionEnabled" -eq "0" ]; then
                err "2" "DISABLED"
    else
        CheckupErr "with check if action is enabled when space is getting low."
    fi
elif [ "$IsAuditInstalled" == "0" ]; then
    err "7" "ERROR: NOT Installed"
else
    CheckupErr "with check if audit is installed."
fi
}

checkLogrotate() {
echo -n "5.4 - Checking  if logrotate is enabled "
isLogrotateInstalled=$(rpm -qa logrotate | wc -l)

if [ "$isLogrotateInstalled" = "0" ]; then
    err "6" "package NOT installed."
elif [ "$isLogrotateInstalled" = "1" ]; then
    logrotateSyslog="/etc/logrotate.d/syslog"
    # check if config file exists
    if [ -e "${logrotateSyslog}" ]; then
        # check if configured log files are not commented out
        countLogs=$(grep "/var/log" ${logrotateSyslog} | grep -v "^#" | wc -l)
        if [ "$countLogs" -gt "0" ]; then
         listLogs=$(grep "/var/log" ${logrotateSyslog} | grep -v "^#" | tr "\n" " ")
         OK "6" "these logs are rotated: ${listLogs}"
        else
         warn "11" "logrotate configured to rotate 0 logs."
        fi
    else
        warn "11" "package installed but ${logrotateSyslog} is missing."
    fi
else
    CheckupErr
fi
}

checkAnacron() {
# anacron should be disabled and crond should ONLY be used for scheduling jobs
echo -n "6.1.1 - Checking  if anacron is enabled "
isAnacronnstalled=$(rpm -qa | egrep -i "anacron" | wc -l)
if [ "${isAnacronnstalled}" = "0" ]; then
    OK "6" "not installed."
elif [ "${isAnacronnstalled}" = "1" ]; then
# is it configured
    isAnacronConfigured=$(cat /etc/anacrontab  | egrep -v "^#"  | grep "run-parts" | wc -l)
    if [ "${isAnacronConfigured}" -gt "0" ]; then
        err "6" "CONFIGURED"
    else
        OK "6" "installed but not configured"
    fi
else
    CheckupErr
fi
}

checkCron() {
echo -n "6.1.2 - Checking  if crond is enabled "
isCrontabInstalled=$(rpm -qa | grep -i "crontab" | wc -l)
if [ "${isCrontabInstalled}" = "0" ]; then
    OK "7" "not installed."
elif [ "${isCrontabInstalled}" = "1" ]; then
# is it configured
isCrontabConfigured=$(cat /etc/crontab  | egrep -v "^#" | grep "run-parts" | wc -l)
    if [ "${isCrontabConfigured}" -gt "0" ]; then
        OK "7"
    else
        warn "11" "installed but not configured - possibly anacron is enabled."
    fi
else
    CheckupErr
fi
}

checkAnacronCrontabPermissions() {
cronFiles="/etc/anacrontab /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d"
COUNTER="2"
for file in ${cronFiles}
 do
COUNTER=$((COUNTER+1))
    echo -n "6.1.${COUNTER} - Checking permission and ownership of ${file}."
    checkPermOwn=$(stat -c "%a %u %g" ${file} | egrep ".00 0 0" | wc -l)
    if [ "${checkPermOwn}" -eq "1" ]; then
        OK "4"
    else
        warn "11" "Please change mode to 600 and ownership to root."
    fi
 done
}

checkAt() {

atdeny="/etc/at.deny"
atallow="/etc/at.allow"

echo -n "6.1.10 - Checking  if at deamon is restricted."
# ! it's easier to maintain allow list,
# -only people in allow file are given permission to execute at jobs."

# check if both files exists
if [ -f ${atallow} ] && [ -f ${atdeny} ]; then
    err "6" "2 files exists which creates a conflict, please remove ${atallow}."
elif [ -f ${atallow} ] && [ ! -f ${atdeny} ]; then
# allow exists but deny not
 # - check permissions
OK "6"
echo -n "6.1.10a - checking for correct permissions/ownership on ${atallow}."
allowPerm=$(stat -c "%a %u %g" ${atallow} |  egrep ".00 0 0" | wc -l )
    if [ "${allowPerm}" -eq "1" ]; then
        OK "3"
    else
        warn "11" "Please make sure this file is owned by root with 600 mode."
    fi
# - check if its empty
echo -n "6.1.10b - checking if ${atallow} is empty."
isAllowEmpty=$(cat ${atallow} |sed '/^$/d' | wc -l | cut -d" " -f -1)
    if [ "${isAllowEmpty}" -gt "0" ]; then
        OK "6"
    elif [ "${isAllowEmpty}" -eq "0" ]; then
        err "6" "NOT RESTRICTED - file is empty."
    else
        CheckupErr "with check if ${atallow} is empty"
    fi
elif [ ! -f ${atallow} ] && [ -f ${atdeny} ]; then
# allow doesn't but deny is
    warn "11" "it's better to maintain ${atallow}."
    echo -n "6.1.10a - checking for correct permissions/ownership on ${atdeny}."
    denyPerm=$(stat -c "%a %u %g" ${atdeny} |  egrep ".00 0 0" | wc -l )
        if [ "${denyPerm}" -eq "1" ]; then
            OK "3"
        else
            warn "11" "Please make sure this file is owned by root with 600 mode."
        fi
    # - check if its empty
    echo -n "6.1.10b - checking if ${atdeny} is empty."
    isDenyEmpty=$(cat ${atdeny} |sed '/^$/d' | wc -l | cut -d" " -f -1)
        if [ "${isDenyEmpty}" -gt "0" ]; then
            OK "6"
        elif [ "${isDenyEmpty}" -eq "0" ]; then
            err "6" "NOT RESTRICTED - file is empty."
        else
            CheckupErr "with check if ${atdeny} is empty"
        fi
elif [ ! -f ${atallow} ] && [ ! -f ${atdeny} ]; then
# none of the files exists
    warn "11" "none of the files exists, which means only superuser can create jobs."
else
    CheckupErr
fi
}

checkCrontabRestriction() {

crondeny="/etc/cron.deny"
cronallow="/etc/cron.allow"

echo -n "6.1.11 - Checking  if crontab access is restricted."
# ! it's easier to maintain allow list,
# -only people in allow file are given permission to execute cron jobs."

# check if both files exists
if [ -f ${cronallow} ] && [ -f ${crondeny} ]; then
    err "5" "2 files exists which creates a conflict, please remove ${cronallow}."
elif [ -f ${cronallow} ] && [ ! -f ${crondeny} ]; then
# allow exists but deny not
# - check permissions
    OK "5"
    echo -n "6.1.10a - checking for correct permissions/ownership on ${cronallow}."
    cronallowPerm=$(stat -c "%a %u %g" ${cronallow} |  egrep ".00 0 0" | wc -l )
        if [ "${cronallowPerm}" -eq "1" ]; then
            OK "3"
        else
            warn "11" "Please make sure this file is owned by root with 600 mode."
        fi
# - check if its empty
    echo -n "6.1.10b - checking if ${cronallow} is empty."
    iscronAllowEmpty=$(cat ${cronallow} |sed '/^$/d' | wc -l | cut -d" " -f -1)
        if [ "${iscronAllowEmpty}" -gt "0" ]; then
            OK "6"
        elif [ "${iscronAllowEmpty}" -eq "0" ]; then
            err "6" "NOT RESTRICTED - file is empty."
        else
            CheckupErr "with check if ${cronallow} is empty"
        fi
elif [ ! -f ${cronallow} ] && [ -f ${crondeny} ]; then
# allow doesn't but deny is
    warn "11" "it's better to maintain ${cronallow}."
    echo -n "6.1.10a - checking for correct permissions/ownership on ${crondeny}."
    crondenyPerm=$(stat -c "%a %u %g" ${crondeny} |  egrep ".00 0 0" | wc -l )
        if [ "${crondenyPerm}" -eq "1" ]; then
            OK "3"
        else
            warn "11" "Please make sure this file is owned by root with 600 mode."
        fi
    # - check if its empty
    echo -n "6.1.10b - checking if ${crondeny} is empty."
    iscronDenyEmpty=$(cat ${crondeny} |sed '/^$/d' | wc -l | cut -d" " -f -1)
        if [ "${iscronDenyEmpty}" -gt "0" ]; then
            OK "6"
        elif [ "${iscronDenyEmpty}" -eq "0" ]; then
            err "6" "NOT RESTRICTED - file is empty."
        else
            CheckupErr "with check if ${crondeny} is empty"
        fi
elif [ ! -f ${cronallow} ] && [ ! -f ${crondeny} ]; then
# none of the files exists
    warn "11" "none of the files exists, which means only superuser can create jobs."
else
    CheckupErr
fi
}

checkSSH() {
sshconfig="/etc/ssh/sshd_config"
echo -n "6.2.1 - Checking if SSH Protocol 2 is set."
SSHprotocol=$(grep "^Protocol" ${sshconfig} | cut -d" " -f 2-)
if [ "${SSHprotocol}" -eq "2" ]; then
    OK "6"
else
    err "6" "DISABLED - need fix."
fi

echo -n "6.2.2 - Checking if SSH VERBOSE LogLevel is set."
SSHlogLevel=$(grep "^LogLevel" ${sshconfig} | cut -d" " -f 2-)
if [ "${SSHlogLevel}" == "VERBOSE" ]; then
    OK "5"
else
    err "5" "DISABLED - please update in ${sshconfig}."
fi

echo -n "6.2.3 - Checking for correct permissions on ${sshconfig}."
SSHDpermissions=$(stat -c "%a %u %g" /etc/ssh/sshd_config | egrep "600 0 0" | wc -l)
if [ "${SSHDpermissions}" -eq "1" ]; then
    OK "3"
else
    err "3" "WRONG Permissions - file must be owned by root with mode 600."
fi

echo -n "6.2.4 - Checking if SSH x11 Forwarding is disabled."
x11Forwarding=$(grep "^X11Forwarding" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${x11Forwarding}" == "no" ]; then
    OK "5"
else
    err "5" "ENABLED"
fi

echo -n "6.2.5 - Checking if SSH MaxAuthTries is set to 4 or less."
maxAuthTriesCount=$(grep "^MaxAuthTries" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${maxAuthTriesCount}" -le "4" ]; then
    OK "4"
else
    err "4" "we have set ${maxAuthTriesCount}."
fi

echo -n "6.2.6 - Checking if SSH IgnoreRhosts is set to 'yes' "
ignoreRhostsCheck=$(grep "^IgnoreRhosts" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${ignoreRhostsCheck}" == "yes" ]; then
    OK "5"
else
    err "5" "DISABLED"
fi

echo -n "6.2.7 - Checking if SSH HostbasedAuthentication is Disabled."
hostbasedAuthCheck=$(grep "^HostbasedAuthentication" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${hostbasedAuthCheck}" == "no" ]; then
    OK "4"
else
    err "4" "ENABLED"
fi

echo -n "6.2.8 - Checking if SSH Root Login is Disabled."
RootLoginCheck=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${RootLoginCheck}" == "no" ]; then
    OK "6"
else
    err "6" "ENABLED"
fi

echo -n "6.2.9 - Checking if SSH Empty passwords are Disabled."
emptyPassCheck=$(grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${emptyPassCheck}" == "no" ]; then
    OK "5"
else
    err "5" "ENABLED"
fi

echo -n "6.2.10 - Checking if SSH PermitUserEnvironment is set to 'no'."
permitUserEnvCheck=$(grep "^PermitUserEnvironment" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${permitUserEnvCheck}" == "no" ]; then
    OK "4"
else
    err "4" "set to 'yes'"
fi

echo -n "6.2.11 - Checking if SSH Approved Ciphers are set"
CiphersCheck=$(grep "^Cipher" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${CiphersCheck}" == "aes128-ctr,aes192-ctr,aes256-ctr" ]; then
    OK "5"
else
    err "5" "NOT set"
fi

echo -n "6.2.12 - Checking if SSH Session TimeOut is enabled"
clientAliveIntervalCheck=$(grep "^ClientAliveInterval" /etc/ssh/sshd_config | cut -d" " -f 2-)
clientAliveCountMaxCheck=$(grep "^ClientAliveCountMax" /etc/ssh/sshd_config | cut -d" " -f 2-)
if [ "${clientAliveIntervalCheck}" -gt "0" ] && [ "${clientAliveCountMaxCheck}" -gt "0" ]; then
    OK "5"
elif [ "${clientAliveIntervalCheck}" -gt "0" ] && [ "${clientAliveCountMaxCheck}" -eq "0" ]; then
    warn "11" "ClientAliveCountMax disabled"
elif [ "${clientAliveIntervalCheck}" -eq "0" ] && [ "${clientAliveCountMaxCheck}" -gt "0" ]; then
    warn "11" "ClientAliveInterval disabled"
else
    err "5" "DISABLED"
fi

echo -n "6.2.13 - Checking if SSH Access is limited"
isAccessLimited=$(grep "^AllowUsers\|^AllowGroups\|^DenyUsers\|^DenyGroups" /etc/ssh/sshd_config | wc -l)
LimitAccessOptions=$(grep "^AllowUsers\|^AllowGroups\|^DenyUsers\|^DenyGroups" /etc/ssh/sshd_config | cut -d" " -f -1 | tr "\n" " ")
if [ "${isAccessLimited}" -gt "0" ]; then
    Notice "6" "Enabled and maintanted by using ${LimitAccessOptions} "
else
    err "6" "DISABLED"
fi

echo -n "6.2.14 - Checking if SSH Banner is Enabled"
isBannerEnabled=$(grep "^Banner" /etc/ssh/sshd_config |wc -l)
if [ "${isBannerEnabled}" -gt "0" ]; then
    OK "6"
else
    err "6" "DISABLED"
fi
}

checkPAM() {
pamconfig="/etc/pam.d/system-auth"

echo -n "6.3.1 - PAM - Checking if pam_cracklib is used"
isCracklibUsed=$(grep "pam_cracklib.so" ${pamconfig} | wc -l)
if [ "${isCracklibUsed}" -gt "0" ]; then
    OK "6"
else
    err "6" "DISABLED"
fi

echo -n "6.3.2 - PAM - Checking if Strong password creation policy is used"
isPasswdqcUsed=$(grep "pam_passwdqc.so" ${pamconfig} | wc -l)
if [ "${isPasswdqcUsed}" -gt "0" ]; then
    OK "3"
else
    err "3" "DISABLED"
fi

echo -n "6.3.3 - PAM - Checking if Lockout for failed attempts is set"
isLockoutEnabled=$(grep "pam_tally2.so" ${pamconfig} | wc -l)
if [ "${isLockoutEnabled}" -gt "0" ]; then
    OK "4"
else
    err "4" "DISABLED"
fi

echo -n "6.3.4 - PAM - Checking if pam_deny.so is used to Deny Services"
isDenyServicesUsed=$(grep "pam_deny.so" /etc/pam.d/system-auth | grep "requisite" | wc -l)
if [ "${isDenyServicesUsed}" -gt "0" ]; then
    #DeniedServices=$(grep "pam_deny.so" /etc/pam.d/system-auth | grep "requisite" | awk -F" " '{print $1}'| tr "\n" " )
    OK "4"
else
    err "4" "NOT CONFIGURED"
fi

echo -n "6.3.5 - PAM - Checking if sha512 is used for password hashing"
checkHashing=$(authconfig --test | grep hashing |awk -F"is " '{print $2}')
if [ "${checkHashing}" == "sha512" ]; then
    OK "4"
else
    err "4" "NOT USED - need fix"
fi

echo -n "6.3.6 - PAM - Checking if there's a limit on reusing old passwords"
checkOldPassLimit=$(grep "remember" /etc/pam.d/system-auth | wc -l)
if [ "${checkOldPassLimit}" -gt "0" ]; then
    OK "3"
else
    err "3" "NOT CONFIGURED"
fi

echo -n "6.3.7 - PAM - Checking if pam_ccreds package is removed"
isPamCcredsInstalled=$(rpm -qa | grep pam_ccreds | wc -l)
if [ "${isPamCcredsInstalled}" -gt "0" ]; then
    err "5" "INSTALLED"
else
    OK "5"
fi
}

checkSystemConsole() {
secttyconf="/etc/securetty"
echo -n "6.4 - Checking for terminals with permission to login directly as root"
checkConsoles=$(wc -l ${secttyconf} | cut -d" " -f -1 )
if [ "${checkConsoles}" -gt "0" ]; then
    warn "11" "${checkConsoles} found - please validate them in ${secttyconf}"
else
    OK "3"
fi
}

checkSUaccess() {
echo -n "6.5 - PAM - Checking su cmd restrictions"
isSuRestricted=$(grep "pam_wheel" /etc/pam.d/su | grep -v "^#" | wc -l)
if [ "${isSuRestricted}" -gt "0" ]; then
    Notice "6" "only users in wheel group can execute sudo"
else
    err "6" "NOT CONFIGURED"
fi
}

checkSystemAccounts() {
getNonSystemUsers=$(grep -v "nologin" /etc/passwd | awk -F":" '($3 >= 500 && $3 > 0 && $1 != "sync" && $1 != "shutdown" && $1 != "halt")  {print $1}')
echo -n "7.1 - Check if System Accounts have no access to interactive shell"

# grep every user without nologin and
# every user with id lower than 500
countAllowedAccounts=$(grep -v "nologin" /etc/passwd | awk -F":" '($3 < 500 && $3 > 0 && $1 != "sync" && $1 != "shutdown" && $1 != "halt" && $1 != "ec2-user")  {print $1, $6}' | wc -l)
if [ "${countAllowedAccounts}" -gt "0" ]; then
    getAccNames=$(grep -v "nologin" /etc/passwd | awk -F":" '($3 < 500 && $3 > 0 && $1 != "sync" && $1 != "shutdown" && $1 != "halt" && $1 != "ec2-user")  {print $1, $7}')
    warn "11" "There are ${countAllowedAccounts} found: ${getAccNames}."
else
    OK "3"
fi

echo -n "7.2.1a - Check if Shadow Password Suite PASS_MAX_DAYS parameter is set"
passExpirationDays=$(grep "PASS_MAX_DAYS" /etc/login.defs  | grep -v "^#" | wc -l)
#check if option is enabled
if [ "${passExpirationDays}" -gt "0" ]; then
getPassExpirationDays=$(grep "PASS_MAX_DAYS" /etc/login.defs  | grep -v "^#" | awk -F" " '{print $2}' )
    #check what the value is
    if [ "${getPassExpirationDays}" -le "90" ]; then
        OK "3"
    elif [ "${getPassExpirationDays}" -gt "90" ] && [ "${getPassExpirationDays}" -le "150" ]; then
        warn "11" "set to ${getPassExpirationDays}"
    elif [ "${getPassExpirationDays}" -ge "150" ]; then
        err "3" "set to ${getPassExpirationDays}"
    fi
else
    err "3" "OPTION NOT SET"
fi

echo  "7.2.1b - Checking password expiration days for non-system users"
# I added this check myself - it was not in Benchmark book and can be disabled anytime
# check the password expiration date for non-system users
for user in ${getNonSystemUsers}
 do
    passExpDays=$(chage -l ${user} | grep "Max" |awk -F": " '{print $2}')
    if [ "${passExpDays}" -le "-1" ]; then
        err "11" "${user} set to NEVER"
    elif [ "${passExpDays}" -gt "-1" ] && [ "${passExpDays}" -le "90" ]; then
        Notice "11" "${user} - OK"
    elif [ "${passExpDays}" -gt "90" ] && [ "${passExpDays}" -lt "150" ]; then
        warn "11" "${user} set to ${passExpDays}"
    elif [ "${passExpDays}" -ge "150" ]; then
        err "11" "${user} set to ${passExpDays}"
    fi
 done

echo -n  "7.2.2a - Checking if Shadow Password Suite PASS_MIN_DAYS parameter is set"
passChangeMinDays=$(grep "PASS_MIN_DAYS" /etc/login.defs | grep -v "^#" | wc -l)
# check if option is enaled
if [ "${passChangeMinDays}" -gt "0" ]; then
    getPassChangeMinDays=$(grep "PASS_MIN_DAYS" /etc/login.defs | grep -v "^#" | awk -F" " '{print $2}')
    #check what the value is
    if [ "${getPassChangeMinDays}" == "0" ]; then
        err "1" "set to 0 - possible that password aging is disabled"
    elif [ "${getPassChangeMinDays}" -gt "0" ] && [ "${getPassChangeMinDays}" -lt "7" ]; then
        warn "11" "set to ${getPassChangeMinDays} - Please increase"
    elif [ "${getPassChangeMinDays}" -ge "7" ]; then
        OK "1"
    fi
else
    err "1" "NOT SET"

fi

echo  "7.2.2b - Checking Minimum number of days between password change"
#==== 7.2.2b =================================================================
#
# I added this check myself - it was not in Benchmark book and can be disabled anytime
# check for min nr of days between pass change on current non-system users
#============================================================================

getNonSystemUsers=$(grep -v "nologin" /etc/passwd | awk -F":" '($3 >= 500 && $3 > 0 && $1 != "sync" && $1 != "shutdown" && $1 != "halt")  {print $1}')
ARRAY_NEGATIVE_OPTION=()
ARRAY_PASSWORD_AGING_DISABLED=()
ARRAY_LESS_THAN_SEVEN_DAYS=()

for user2 in ${getNonSystemUsers}
 do
     PassChangeMinDays2=$(chage -l ${user2} | grep "Min" | awk -F": " '{print $2}')
     if [ "${PassChangeMinDays2}" -lt "0" ]; then
        ARRAY_NEGATIVE_OPTION+=( "${user2} " )
     elif [ "${PassChangeMinDays2}" -eq "0" ]; then
        ARRAY_PASSWORD_AGING_DISABLED+=( "${user2}" )
     elif [ "${PassChangeMinDays2}" -gt "0" ] && [ "${PassChangeMinDays2}" -lt "7" ]; then
        ARRAY_LESS_THAN_SEVEN_DAYS+=( "${user2} " )
     elif [ "${PassChangeMinDays2}" -ge "7" ]; then
        OK "11"
     else
         err "11" "${user2} has wrong value"
     fi
done

LIST_USERS_WITH_NEGATIVE_OPTION=$(echo "${ARRAY_NEGATIVE_OPTION[@]}" |tr ' ' '\n' \
| sort -u | tr '\n' ' ')
WARNINGA=$(echo "Users with option -1: ${LIST_USERS_WITH_NEGATIVE_OPTION} ")
LIST_USERS_WITH_PASSWORD_AGING_DISABLED=$(echo "${ARRAY_PASSWORD_AGING_DISABLED[@]}" \
| tr ' ' '\n' | sort -u | tr '\n' ' ')
WARNINGB=$(echo "Users with password aging disabled:    \
${LIST_USERS_WITH_PASSWORD_AGING_DISABLED} ")
LIST_USERS_PASSWORD_WITH_7DAYS_AGING=$(echo "${ARRAY_LESS_THAN_SEVEN_DAYS[@]}" |    \
tr ' ' '\n' | sort -u | tr '\n' ' ')
WARNINGC=$(echo "Users with option set to less than 7days:                          \
${LIST_USERS_PASSWORD_WITH_7DAYS_AGING} ")
ALLWARNINGS=$(echo -e "${WARNINGA}\n \t\t\t\t\t\t\t\t\t\t\t${WARNINGB}\n \
\t\t\t\t\t\t\t\t\t\t\t${WARNINGC} ")
ALL_ARRAYS=( "${ARRAY_NEGATIVE_OPTION[@]}" "${ARRAY_USERS_WITH_PASSWORD_AGING_DISABLED[@]}" \
 "${ARRAY_LESS_THAN_SEVEN_DAYS[@]}" )
count_warnings=$(echo "${ALL_ARRAYS[@]}" | sed '/^\s*$/d' | wc -l)

if [ "${count_warnings}" -gt "0" ]; then
    warn "11" "${ALLWARNINGS}"
else
    OK "5"
fi

echo -n  "7.2.3a - Checking if Shadow Password Suite PASS_WARN_AGE parameter is set"
passWarnAge=$(grep "PASS_WARN_AGE" /etc/login.defs | grep -v "^#" | wc -l)
if [ "${passWarnAge}" -gt "0" ]; then
    # check values
    getPassWarnAge=$(grep "PASS_WARN_AGE" /etc/login.defs | grep -v "^#" | awk -F" " '{print $2}' | wc -l)
    if [ "${getPassWarnAge}" -lt "7" ]; then
        err "1" "less than 7 days set"
    elif [ "${getPassWarnAge}" -ge "7" ]; then
        Notice "1" "7 or more days set"
    fi
else
    err "1" "NOT SET"
fi

echo  "7.2.3b - Checking Minimum of days of warning before password expires"
# I added this check myself - it was not in Benchmark book and can be disabled anytime
# check for min of days of warning before pass expires on non-system users
for user3 in ${getNonSystemUsers}
 do
    getPassWarAge2=$(chage -l ${user3} | grep "warning" | awk -F": " '{print $2}')
    if [ "${getPassWarAge2}" -le "0" ]; then
        err "11" "${user3} 0 or less - probably DISABLED"
    elif [ "${getPassWarAge2}" -gt "0" ] && [ "${getPassWarAge2}" -lt "7" ]; then
        warn "11" "${user3} less than 7 days"
    elif [ "${getPassWarAge2}" -ge "7" ]; then
        Notice "11" "${user3} 7 or more"
    fi
 done

echo -n  "7.3 - Checking default group for root account"
rootGroup=$(grep "^root" /etc/passwd | cut -f4 -d:)
if [ "${rootGroup}" == "0" ]; then
    OK "6"
else
    err "6" "WRONG GROUP"
fi

COUNTER="0"
files="/etc/bashrc /etc/profile"
for file in ${files}
 do
COUNTER=$((COUNTER+1))
echo -n  "7.4.${COUNTER} - Checking if default umask is set to 077 in ${file}"
    checkUmask=$(grep -i "^umask" ${file}| wc -l )
    if [ "${checkUmask}" -gt "0" ]; then
        getUmaskValue=$(grep -i "^umask" ${file} | awk -F'[ =]' '{print $2}')
        if [ "${getUmaskValue}" == "077" ]; then
            OK "4"
        else
            warn "11" "set to ${getUmaskValue}"
        fi
    else
        err "4" "NOT SET"
    fi
 done

echo -n  "7.5 - Checking if inactive accounts are being disabled"
# defaults are set in etc/default/useradd
checkInactiveFeature=$(useradd -D | grep -i inactive |cut -d"=" -f 2-)
if [ "${checkInactiveFeature}" == "-1" ]; then
    err "5" "FEATURE DISABLED"
elif [ "${checkInactiveFeature}" == "0" ]; then
    Notice "5" "as soon as password expires"
elif [ "${checkInactiveFeature}" -gt "0" ]; then
    Notice "5" "after ${checkInactiveFeature}"
else
    CheckupErr "5" "with check - 7.5"
fi
}

checkBanner() {
COUNTER="0"
configFiles="/etc/issue /etc/motd"
for file in ${configFiles}
 do
    COUNTER=$((COUNTER+1))
    echo -n "8.1.a${COUNTER} - Checking Warning Banner for standard login services in ${file}"
    BannerExistence=$(grep -i "restricted\|authorized\|warning" ${file} | wc -l)
    if [ "${BannerExistence}" -gt "0" ]; then
        OK "2"
    else
        warn "11" "NOT SET"
    fi
 done

cFiles="/etc/issue /etc/issue.net /etc/motd"
COUNTER="0"
for i in ${cFiles}
 do
    OSinfo=$(egrep '(\\v|\\r|\\m|\\s)' ${file} | wc -l)
    COUNTER=$((COUNTER+1))
    echo -n "8.1.1.${COUNTER} - Checking if OS information is removed from Banner in ${file}"
    if [ "${OSinfo}" -eq "0" ]; then
        OK "1"
    else
        warn "11" "INCLUDED"
    fi
 done

#echo -n "8.2 Check for warnin info in Gnome Banner"
# NOT CHECKED SINCE WE'RE NOT USING GUI
# but it might be worth to have this check here for the future
#  - to implement later --
}

# 9 - System Maintenance
checkSystem() {
echo  "9.1 - Verify correct permissions on packaged system files"
echo  "LIST OF FILES WITH WRONG PERMISSIONS:"
allpkgs="$(pwd)/all_packages.tmp"
rpm -qa >>${allpkgs}

while read line
 do
    packagePerm=$(rpm -V --nomtime --nosize --nomd5 --nolinkto ${line} | wc -l)
    if [ "${packagePerm}" -eq "0" ]; then
        OK "1" >> /dev/null
    elif [ "${packagePerm}" -gt "0" ]; then
    #showPackageFiles=$(rpm -V --nomtime --nosize --nomd5 --nolinkto ${line} |awk -F" " '{print $2}')
    showPackageFiles=$(rpm -V --nomtime --nosize --nomd5 --nolinkto ${line} |cut -d"/" -f2- |sed "s/^/\//g")
        warn "11" "Found ${packagePerm} files with wrong permissions."
        for i in ${showPackageFiles}
         do
            Notice "1" "${i} - can be fixed with rpm --setperms ${line}."
         done
    else
        CheckupErr "with check for file permissions on package ${line}."
    fi
 done <${allpkgs}

rm -rf ${allpkgs}

# check permissions on config files
# for monitoring if these file are changed we could use monit, tripwire, other mechanism
passFile="/etc/passwd"
echo -n  "9.1.1 - Verify permissions on ${passFile}"
passFilePerms=$(stat -c "%a" ${passFile})
if [ "${passFilePerms}" -eq "644" ]; then
    OK "6"
else
    warn "11" "${passFilePerms} INSTEAD OF 644"
fi

shadowFile="/etc/shadow"
echo -n  "9.1.2 - Verify permissions on ${shadowFile}"
shadowFilePerms=$(stat -c "%a" ${shadowFile})
if [ "${shadowFilePerms}" -eq "400" ]; then
    OK "6"
else
    warn "11" "${shadowFilePerms} INSTEAD OF 400"
fi

gshadowFile="/etc/gshadow"
echo -n  "9.1.3 - Verify permissions on ${gshadowFile}"
gshadowFilePerms=$(stat -c "%a" ${gshadowFile})
if [ "${gshadowFilePerms}" -eq "400" ]; then
    OK "6"
else
    warn "11" "${gshadowFilePerms} INSTEAD OF 400"
fi

groupFile="/etc/group"
echo -n  "9.1.4 - Verify permissions on ${groupFile}"
groupFilePerms=$(stat -c "%a" ${groupFile})
if [ "${groupFilePerms}" -eq "644" ]; then
    OK "6"
else
    warn "11" "${groupFilePerms} INSTEAD OF 400"
fi

files_to_verify="/etc/passwd /etc/shadow /etc/gshadow /etc/group"
COUNTER="4"
for c in ${files_to_verify}
 do
    COUNTER=$((COUNTER+1))
    echo -n  "9.1.${COUNTER} - Verify User/Group ownership on ${c}"
    verify_file_permissions=$(stat -c "%u %g" ${c})
    if [ "${verify_file_permissions}" == "0 0" ]; then
        OK "5"
    else
        warn "11" "${c} NOT OWNED BY root"
    fi

 done

## find world writable files:
echo -n  "9.1.9 - Checking for world writable files"
count_world_writable_files=$(find / -type f -perm -2 -print 2>/dev/null |xargs sudo file |egrep -v "/proc" | wc -l)
show_ww_files=$(find / -type f -perm -2 -print 2>/dev/null |xargs sudo file |egrep -v "/proc" )
if [ "${count_world_writable_files}" -eq "0" ]; then
    Notice "6" "OK - none found"
else
    warn "11" "${count_world_writable_files} FOUND"
    Notice "2" "${show_ww_files}"
fi

## IMPLEMENT THIS CHECK AT THE END !!
## find all broken symbolic links:
#find_broken_symlinks=$(find -L  / -type l 2>/dev/null -print | wc -l)

echo -n  "9.1.10 - Checking for un-owned files and directories"
count_unowned_files=$(find / \( -type f -o -type d \) -nouser -print 2>/dev/null  | wc -l)
show_ufiles=$(find / \( -type f -o -type d \) -nogroup -print 2>/dev/null )
if [ "${count_unowned_files}" -eq "0" ]; then
    Notice "5" "OK - none found"
else
    warn "11" "${count_unowned_files} FOUND"
    Notice "2" "${show_ufiles}"
fi

echo -n  "9.1.11 - Checking for un-grouped files and directories"
count_ungrouped_files=$(find / \( -type f -o -type d \) -nouser -print 2>/dev/null  | wc -l)
show_ugfiles=$(find / \( -type f -o -type d \) -nogroup -print 2>/dev/null )
if [ "${count_ungrouped_files}" -eq "0" ]; then
    Notice "5" "OK - none found"
else
    warn "11" "${count_ungrouped_files} FOUND"
    Notice "2" "${show_ugfiles}"
fi

echo -n  "9.1.12 - Checking for SUID system executables"
# ===== NOTE: ========================================================
# A favorite trick of crackers is to exploit SUID-root programs,
# then leave a SUID program as a back door to get in the next time,
# even if the original hole is plugged.
# ===================================================================
count_suid_files=$(find / -xdev -perm -4000 -print 2>/dev/null | wc -l)
show_suid_files=$(find / -xdev -perm -4000 -print 2>/dev/null)
COUNTER="0"
if [ "${count_suid_files}" -eq "0" ]; then
    err "5" "NONE found - check if there are files that need suid permissions."
elif [ "${count_suid_files}" -gt "0" ]; then
    Notice "5" "${count_suid_files} - make sure they need it."
    # checking for integrity with default permissions from rpm package
    for i in ${show_suid_files}
     do
        COUNTER=$((COUNTER+1))
        echo -n "9.1.12.${COUNTER} - checking if SUID is set by rpm pacakge on ${i}"
        verify_suid_file=$(rpm -V $(rpm -qf ${i}) | grep "${i}" | wc -l)
        if [ "${verify_suid_file}" -eq "0" ]; then
            OK "5"
        else
            warn "11" "check this file as SUID should not be set by default"
        fi
     done
fi

echo -n  "9.1.13 - Checking for SGID system executables"
# ===== NOTE: ========================================================
# A favorite trick of crackers is to exploit SGID-root programs,
# then leave a SUID program as a back door to get in the next time,
# even if the original hole is plugged.
# ===================================================================
count_sgid_files=$(find / -xdev -perm -02000 -print 2>/dev/null | wc -l)
show_sgid_files=$(find / -xdev -perm -02000 -print 2>/dev/null)
COUNTER="0"
if [ "${count_sgid_files}" -eq "0" ]; then
    err "5" "NONE found - check if there are files that need suid permissions."
elif [ "${count_sgid_files}" -gt "0" ]; then
    Notice "5" "${count_sgid_files} - make sure they need it."
    # checking for integrity with default permissions from rpm package
    for i in ${show_sgid_files}
     do
        COUNTER=$((COUNTER+1))
        echo -n "9.1.13.${COUNTER} - checking if SGID is set by rpm pacakge on ${i}"
        verify_sgid_file=$(rpm -V $(rpm -qf ${i}) | grep "${i}" | wc -l)
        if [ "${verify_sgid_file}" -eq "0" ]; then
            OK "5"
        else
            warn "11" "check this file as SUID should not be set by default"
        fi
     done
fi

echo -n  "9.2.1 - Checking if password fields are empty"
count_users_without_passwords=$(cat /etc/shadow | awk -F":" '($2 == "" ) {print $1 " does not have a password "}' | wc -l)
users_without_passwords=$(cat /etc/shadow | awk -F":" '($2 == "" ) {print $1}' )
if [ "${count_users_without_passwords}" -gt "0" ]; then
    warn "11" "${count_users_without_passwords} FOUND"
    Notice "12" "Make sure these accounts are secured: ${users_without_passwords}"
else
    OK "7"
fi

etc_config_files="/etc/passwd /etc/shadow /etc/group"
COUNTER="1"
for d in ${etc_config_files}
 do
    COUNTER=$((COUNTER+1))
    echo -n  "9.2.${COUNTER} - Checking if Legacy + entries exists in ${d}"
    count_legacy_entries=$(grep '^+:' ${d}| wc -l)
    if [ "${count_legacy_entries}" -gt "0" ]; then
        err "5" "${count_legacy_entries} FOUND"
    else
        OK "5"
    fi
 done

echo -n  "9.2.5 - Checking if there is an account with UID 0 other than root"
count_superuser_uids=$(cat /etc/passwd | awk -F":" '($3 == "0") { print $1}' | wc -l)
if [ "${count_superuser_uids}" -eq "0" ]; then
    err "4" "NONE FOUND - root uid is not 0"
elif [ "${count_superuser_uids}" -eq "1" ]; then
    #check if answer is root
    get_superuser=$(cat /etc/passwd | awk -F":" '($3 == "0") { print $1}' )
    if [ "${get_superuser}" == "root" ]; then
        OK "4"
    else
        err "4" "root doesn't have UID of 0 but ${get_superuser} - NEED FIX"
    fi
elif [ "${count_superuser_uids}" -gt "1" ]; then
    get_bad_superuser=$(cat /etc/passwd | awk -F":" '($3 == "0") { print $1}' | grep -v "^root$")
    warn "11" "${count_superuser_uids} FOUND - change uid of ${get_bad_superuser} "
fi

echo  -n "9.2.6 - Checking root PATH integrity"
ROOT_PATH_WARNINGS=()
if [ "`echo $PATH | /bin/grep :: `" != "" ]; then
     #WARN1=( "Empty Directory in PATH (::)" )
     ROOT_PATH_WARNINGS+=( "Empty Directory in PATH (::)" )
fi
if [ "`echo $PATH | /bin/grep :$`" != "" ]; then
    #WARN2=( "Trailing : in PATH" )
    ROOT_PATH_WARNINGS+=( "Trailing : in PATH" )
fi

p=`echo $PATH | /bin/sed -e 's/::/:/' -e 's/:$//' -e 's/:/ /g'`
set -- $p
while [ "$1" != "" ]; do
    if [ "$1" = "." ]; then
        ROOT_PATH_WARNINGS+=( "PATH contains .")
        shift
        continue
    fi
    if [ -d $1 ]; then
        dirperm=`/bin/ls -ldH $1 | /bin/cut -f1 -d" "`
        if [  `echo $dirperm | /bin/cut -c6 ` != "-" ]; then
            ROOT_PATH_WARNINGS+=( "Group Write permission set on directory $1" )
        fi
        if [ `echo $dirperm | /bin/cut -c9 ` != "-" ]; then
            ROOT_PATH_WARNINGS+=( "Other Write permission set on directory $1" )
        fi
        dirown=`ls -ldH $1 | awk '{print $3}'`
        if [ "$dirown" != "root" ]; then
            ROOT_PATH_WARNINGS+=( "$1 is not owned by root")
        fi
    else
        ROOT_PATH_WARNINGS+=( "$1 is not a directory")
    fi
    shift
done

count_warnings=$(echo "${ROOT_PATH_WARNINGS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${ROOT_PATH_WARNINGS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "7"
fi

echo  -n "9.2.7 - Verifying correct permissions on user's home directories"
#==== 9.2.7 =================================================================
#
# Group or world-writable user home directories may enable malicious users
# to steal or modify other user's data or to gain another user's
# system privileges.
#============================================================================

##usr_homes=$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' | /bin/awk -F: '($8 == "PS" && $7 != "/sbin/nologin") {print $6}')
#### - what PS does here??

usr_homes=$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' \
| /bin/awk -F":" '($7 != "/sbin/nologin") {print $6}')

HOME_PERMISSION_WARNING=()
for dir in ${usr_homes}
 do
    if [ ! -d "${dir}" ]; then
        HOME_PERMISSION_WARNING+=( "${dir} DOES NOT EXIST" )
    else
        dirperm=$(ls -ld $dir | cut -f1 -d " ")
        if [ `echo $dirperm | cut -c6` != "-" ]; then
            HOME_PERMISSION_WARNINGS+=("Group WRITE permission set on directory ${dir}")
        fi
        if [ `echo $dirperm | cut -c8` != "-" ]; then
            HOME_PERMISSION_WARNINGS+=("Other READ permission set on directory ${dir}")
        fi
        if [ `echo $dirperm | cut -c9` != "-" ]; then
            HOME_PERMISSION_WARNINGS+=("Other WRITE permission set on directory ${dir}")
        fi
        if [ `echo $dirperm | cut -c10` != "-" ]; then
            HOME_PERMISSION_WARNINGS+=("Other EXECUTE permission set on directory ${dir}")
        fi
    fi
done

count_warnings=$(echo "${HOME_PERMISSION_WARNINGS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${HOME_PERMISSION_WARNING[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "3"
fi

echo  -n "9.2.8 - Checking user dot file permissions"
#==== 9.2.8 =================================================================
#
# Group or world-writable user configuration files may enable malicious
# users to steal or modify other users' data or to gain another user's
# system privileges.
#============================================================================

usr_homes=$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' \
| /bin/awk -F":" '($7 != "/sbin/nologin") {print $6}')

DOT_WARNINGS=()
for dir in ${usr_homes}
 do
    for file in ${dir}/.[A-Za-z0-9]*
     do
        if [ ! -h "${file}" -a -f "${file}" ]; then
            fileperm=`ls -ld ${file} | cut -f1 -d" "`
            if [ `echo ${fileperm} | cut -c6 ` != "-" ]; then
                DOT_WARNINGS+=( "Group Write permission set on file ${file}" )
            fi
            if [ `echo ${fileperm} | cut -c9 ` != "-" ]; then
                DOT_WARNINGS+=( "Other Write permission set on file ${file}" )
            fi
        fi
     done
 done

count_warnings=$(echo "${DOT_WARNINGS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${DOT_WARNINGS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "6"
fi

echo  -n "9.2.9 - Checking permissions on user .netrc files"
#==== 9.2.9 =================================================================
#
# .netrc files may contain unencrypted passwords that may be used to attack
# other systems.
#============================================================================

usr_home=$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' \
| /bin/awk -F":" '($7 != "/sbin/nologin") {print $6}')

NETRC_WARNINGS=()
for file in ${user_home}/.netrc
 do
    if [ ! -h "${file}" -a -f "${file}" ]; then
        fileperm=$(ls -ld ${file} | cut -f1 -d" ")
        if [ `echo ${fileperm} | cut -c5 ` != "-" ]; then
            NETRC_WARNING+=( "Group Read set on $file" )
        fi
        if [ `echo ${fileperm} | cut -c6 ` != "-" ]; then
            NETRC_WARNING+=( "Group Write set on $file" )
        fi
        if [ `echo ${fileperm} | cut -c7 ` != "-" ]; then
            NETRC_WARNING+=( "Group Execute set on $file" )
        fi
        if [ `echo ${fileperm} | cut -c8 ` != "-" ]; then
            NETRC_WARNING+=( "Other Read set on $file" )
        fi
        if [ `echo ${fileperm} | cut -c9 ` != "-" ]; then
            NETRC_WARNING+=(  "Other Write set on $file" )
        fi
        if [ `echo ${fileperm} | cut -c10 ` != "-" ]; then
            NETRC_WARNING+=( "Other Execute set on $file" )
        fi
    fi
done

count_warnings=$(echo "${NETRC_WARNINGS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${NETRC_WARNINGS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "5"
fi

echo  -n "9.2.10 - Checking for presence of user .rhosts files"
#==== 9.2.10 =================================================================
#
# Even though the .rhosts files are ineffective if support is disabled in
# /etc/pam.conf, thye may have been brought over from other systems
# and could contain information useful to an attacker for those other
# systems.
#============================================================================

usr_home=$(/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' \
| /bin/awk -F":" '($7 != "/sbin/nologin") {print $6}')

RHOST_WARNINGS=()
for dir in ${usr_home}
 do
    for file in ${dir}/.rhosts;
     do
        if [ ! -h "${file}" -a -f "${file}" ]; then
            RHOST_WARNINGS+=( "file exists in $dir" )
        fi
     done
 done

count_warnings=$(echo "${RHOST_WARNINGS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${RHOST_WARNINGS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "6"
fi

echo  -n "9.2.11 - Checking group consistency in /etc/passwd and /etc/group"
#==== 9.2.11 =================================================================
#
# Groups defined in the /etc/passwd file not in the /etc/group file pose
# a threat to system security since group permissions are not propperly
# managed.
#============================================================================

pFile="/etc/passwd"
gFile="/etc/group"
DEF_USERS=$(/bin/awk -F":" '{print $1}' ${pFile})
USER_GROUPS=$(cat ${pFile} |cut -d":" -f4)

NONE_EXISTENT_GROUP=()
for group in ${USER_GROUPS}
 do
    group_existence=$(grep "${group}" ${gFile} | wc -l)
    if [ "${group_existence}" -eq "0" ]; then
        get_username=$(grep "${group}" ${pFile} |cut -d: -f1)
        NONE_EXISTENT_GROUP+=( "Groupid ${group} does not exist in /etc/group, but is used by ${get_username} ")
    fi
 done

count_warnings=$(echo "${NONE_EXISTENT_GROUP[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${NONE_EXISTENT_GROUP[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "4"
fi

echo  -n "9.2.12 - Checking if home directory is assigned to users"
#==== 9.2.12 =================================================================
#
# The /etc/passwd fiel defines a home directory that the usre is placed in
# upon login. If there is no defined home directory, the user will be placed
# in "/" and will not be able to write any files or have local environment
# set.
#============================================================================

DEF_USERS=$(/bin/awk -F":" '{print $1}' /etc/passwd)
pFile="/etc/passwd"

NOT_DEFINED_HOME_WARNING=()
for d in ${DEF_USERS}
 do
    home_dir=$(grep "${d}" ${pFile} |cut -d":" -f6 | sed '/^\s*$/d' | wc -l)
    if [ "${home_dir}" -eq "0" ]; then
        NOT_DEFINED_HOME_WARNING+=( "User ${d} has no home directory" )
    fi
 done

count_warnings=$(echo "${NOT_DEFINED_HOME_WARNING[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${NOT_DEFINED_HOME_WARNING[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "5"
fi

echo  -n "9.2.13 - Checking if assigned home exist"
#==== 9.2.13 =================================================================
#
# If the user's home directory does not exist, the user will be placed in "/"
# and will not be able to write any files or have local environment
# variables set.
#============================================================================

pFile="/etc/passwd"
DEF_USERS=$(/bin/awk -F":" '{print $1}' ${pFile})

NOT_EXISTENT_HOME_WARNING=()
for d in ${DEF_USERS}
 do
    home_defined=$(grep "^${d}" ${pFile} |cut -d":" -f6 | sed '/^\s*$/d' | wc -l)
    if [ "${home_defined}" -gt "0" ]; then
        user_home=$(grep "^${d}" ${pFile} |cut -d":" -f6 | sed '/^\s*$/d')
        if [ ! -d "${user_home}" ]; then
            NOT_EXISTENT_HOME_WARNING+=( "${user_home} " )
        fi
    fi
 done

count_warnings=$(echo "${NOT_EXISTENT_HOME_WARNING[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    NON_EXISTENT_HOMES=$(echo "${NOT_EXISTENT_HOME_WARNING[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    warn "11" "THESE DO NOT EXIST: ${NON_EXISTENT_HOMES}"
else
    OK "5"
fi

echo  -n "9.2.14 - Verifying correct ownership on user's home directories"
#==== 9.2.14 =================================================================
#
# Since the user is accountable for files stored in the user home directory,
# the user must be the owner of the directory.
#============================================================================

pFile="/etc/passwd"
USERS=$(/bin/cat ${pFile} | /bin/egrep -v '(root|halt|sync|shutdown)'    \
| /bin/awk -F":" '($7 != "/sbin/nologin") {print $1}')

HOME_OWNERSHIP_WARNING=()
for usr in ${USERS}
 do
usr_homes=$(grep "${usr}" ${pFile} | /bin/awk -F":" '{print $6}')
    for dir in ${usr_homes}
     do
        if [ ! -d "${dir}" ]; then
            HOME_OWNERSHIP_WARNING+=( "${dir} DOES NOT EXIST" )
        else
            dirown=$(ls -ld $dir | cut -f3 -d " ")
            if [ "${dirown}" != "${usr}" ]; then
                HOME_OWNERSHIP_WARNING+=("${usr} set as owner on directory ${dir}")
            fi
        fi
    done
 done

count_warnings=$(echo "${HOME_OWNERSHIP_WARNING[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    for i in "${HOME_OWNERSHIP_WARNING[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "4"
fi

echo  -n "9.2.15 - Check for duplicate UIDs"
#==== 9.2.15 =================================================================
#
# Users must be assigned unique UIDs for accountability and to ensure
# approppriate access protections.
#============================================================================

pFile="/etc/passwd"
tmpCountFile="$(pwd)/counted_uids.tmp"
DUPLICATE_UIDS=()
cat ${pFile} | cut -f3 -d":" | sort -n | uniq -c >>${tmpCountFile}

while read line
do
    UID_COUNT=$(echo "${line}" | cut -d" " -f1)
    User_ID=$(echo "${line}" | cut -d" " -f2)
    if [ "${UID_COUNT}" -gt "1" ]; then
        users=$(grep "${User_ID}" ${pFile} | cut -f1 -d":" |tr "\n" " ")
        DUPLICATE_UIDS+=( "${UID_COUNT} users with the same UID ${users}" )
    fi
done < ${tmpCountFile}

count_uid_warnings=$(echo "${DUPLICATE_UIDS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_uid_warnings}" -gt "0" ]; then
    for i in "${DUPLICATE_UIDS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "7"
fi

rm -rf ${tmpCountFile}

echo  -n "9.2.16 - Check for duplicate GIDs"
#==== 9.2.16 =================================================================
#
# Usergroups must be assigned unique GIDs for accountability and to ensure
# approppriate access protections.
#============================================================================

gFile="/etc/group"
tmpCountFile2="$(pwd)/counted_gids.tmp"
DUPLICATE_GIDS=()
cat ${gFile} | cut -f3 -d":" | sort -n | uniq -c | sed -e 's/^[ \t]*//' >>${tmpCountFile2}

while read line
do
    GID_COUNT=$(echo "${line}" | cut -d" " -f1)
    Group_ID=$(echo "${line}" | cut -d" " -f2)
    if [ "${GID_COUNT}" -gt "1" ]; then
        groups=$(grep "${Group_ID}" ${gFile} | cut -f1 -d":" |tr "\n" " ")
        DUPLICATE_GIDS+=( "${GID_COUNT} groups with GID ${Group_ID}:  ${groups}" )
    fi
done < ${tmpCountFile2}

count_gid_warnings=$(echo "${DUPLICATE_GIDS[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_gid_warnings}" -gt "0" ]; then
    for i in "${DUPLICATE_GIDS[@]}"
     do
        warn "11" "${i}"
     done
else
    OK "7"
fi

rm -rf ${tmpCountFile2}

echo  -n "9.2.17 - Check that reserved UIDs are assigned to System Accounts"
#==== 9.2.17 =================================================================
#
# If a user is assigned a UID that is in the reserved range, even if it is
# not presently in use, security exposures can arise if a subsequently
# installed application uses the same UID.
#============================================================================

pFile="/etc/passwd"
tmp_user_list="$(pwd)/user_list_500.tmp"
tmp_system_accounts="$(pwd)/system_accounts.tmp"

# BELOW LIST MAY VARY DEPENDING ON THE SYTEM SETTINGS
echo "root bin daemon adm lp sync shutdown halt mail news uucp \
operator games gopher ftp nobody nscd vcsa rpc mailnull smmsp pcap ntp \
dbus avahi sshd rpcuser nfsnobody haldaemon avahi-autoipd distcache \
apache oprofile webalizer dovecot squid named xfs gdm sabayon tomcat \
saslauth puppet tcpdump postfix" \
| tr " " "\n" >> ${tmp_system_accounts}

/bin/cat ${pFile} | /bin/awk -F":" '($3 < 500) {print $1" "$3}' >>${tmp_user_list}
BAD_USER=()

while read line
do
    USR=$(echo ${line} | cut -d" " -f1)
    Check_User=$(grep ${USR} ${tmp_system_accounts} | wc -l)
    if [ "${Check_User}" -eq "0" ]; then
        BAD_USER+=( "${USR}" )
    fi
done < ${tmp_user_list}

count_warnings=$(echo "${BAD_USER[@]}" | sed '/^\s*$/d' | wc -l)
if [ "${count_warnings}" -gt "0" ]; then
    LIST_BAD_USERS=$(echo "${BAD_USER[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        warn "11" "potential non-system accounts: ${LIST_BAD_USERS}"
else
    OK "3"
fi

rm -rf ${tmp_system_accounts} ${tmp_user_list}

echo  -n "9.2.18 - Check for duplicate Usernames"
#==== 9.2.18 =================================================================
#
# If a user is assigned a duplicate username, it will create and have access
# to files with the first UID for that username in /etc/passwd. For example:
# uf 'test4' has UID of 1000 and subsequent 'test4' entry has UID of 2000,
# logging in as 'test4' will use UID of 1000. Effectively, the UID is shared
# which is a security problem.
#============================================================================

pFile="/etc/passwd"
COUNT_DUPLICATE_USERNAMES=$(cat ${pFile} | cut -f1 -d":" | sort -n | uniq -d  | wc -l)
DUPLICATE_USERNAMES=$(cat ${pFile} | cut -f1 -d":" | sort -n | uniq -d | tr "\n" " " )

if [ "${COUNT_DUPLICATE_USERNAMES}" -gt "0" ]; then
    warn "11" "FOUND: ${DUPLICATE_USERNAMES} "
else
    OK "7"

fi

echo  -n "9.2.19 - Check for duplicate Groupnames"
#==== 9.2.19 =================================================================
#
# If a group is assigned a duplicate groupname, it will create and have
# access to files with the first GID for that group in /etc/group.
# Effectively, the GID is shared, which is a security problem.
#============================================================================

gFile="/etc/group"
COUNT_DUPLICATE_GROUPNAMES=$(cat ${gFile} | cut -f1 -d":" | sort -n | uniq -d  | wc -l)
DUPLICATE_GROUPNAMES=$(cat ${gFile} | cut -f1 -d":" | sort -n | uniq -d | tr "\n" " ")

if [ "${COUNT_DUPLICATE_GROUPNAMES}" -gt "0" ]; then
    warn "11" "FOUND: ${DUPLICATE_GROUPNAMES} "
else
    OK "7"
fi

}

## 2nd way
if [ "$AUDITMODE" = "0" ]; then
    echo -e "\033[1;36mNOTICE: Audit Only Mode On - no changes will be made. \033[m"

            echo -n "1.1.1a - Checking if $TMP is on separate partition "
        if [ "$CheckTmpMount" = "0" ]; then
            #TmpMountErr
            err "5" "/tmp NOT MOUNTED ON SEPARATE PARTITION"
            skipNoticeA "Skipping parameter checks for $1 mount point."

            # check fstab even though /tmp is not mounted and display warning if /tmp is not mounted but is in /etc/fstab file
                echo -n "1.1.1b - Checking $fstabName for $TMP "
                    if [ "$CheckTmpFstab" = "0" ]; then
                        #FstabNoTmpErr
                        err "6" " $TMP missing from $fstabName"
                        skipNoticeA "Skipping parameter checks for $TMP in $fstabName file."

                    else
                        warn "11" "$TMP is NOT mounted but exist in $fstabName file !"
                    fi
        elif [ "$CheckTmpMount" = "1" ]; then
                OK "5"
                TmpCheck
                FstabTmpCheck

        else
                CheckupErr
        fi
            CheckVar
            FstabVarCheck
            CheckVarTmp
            FstabVarTmpCheck
            FstabVarlogCheck
            CheckVarLog # and check if /var/log is in /etc/fstab
            FstabVarLogAuditCheck
            CheckVarLogAudit # test
            #FstabVarlogCheck
            #FstabVarLogAuditCheck
            CheckHome
            FstabHomeCheck
            checkHomeNodev
            fstabHomeNodevCheck
            #
            CheckRemovableMediaMount
            CheckRemovableMediaFstab
            RemMediaMsg
            CheckNodevDevShmMount
            CheckNodevDevShmFstab
            CheckNosuidDevShmMount
            CheckNosuidDevShmFstab
            CheckNoexecDevShmMount
            CheckNoexecDevShmFstab
            CheckStickyBits
            checkOSrelease
            GPGcheck
            checkYumUpdatesd
            checkUpdates
            VerifyPackageIntegrity
            checkAIDEinstalled
            checkGrubOwner
            grubPassCheck
            singleModeCheck
            checkInteractiveBoot
            checkRestrictionCoreDumps
            checkBufferOverFlowProtection
            checkRandomizedVAspace
            checkNXsupport
            checkPrelink
            checkServerClientServices
            checkXinetdService
            checkStreamDgramServices
            checkTcpmuxServer
            checkUmask
            checkXwindow
            checkAvahi
            checkCUPSservice
            checkDHCPservice
            checkNTPservice
            checkNFSRPCservice
            checkServices
            checkServices2
            checkSMTP
            checkHostOnlyNetworkParameters
            checkNetworkHostRouterParameters
            checkTcpWrappers
            checkHostAllowDeny
            checkIPtables
            checkUncommonProtocols
            checkSyslog
            checkRsyslog
            checkAuditd
            checkLogrotate
            checkAnacron
            checkCron
            checkAnacronCrontabPermissions
            checkAt
            checkCrontabRestriction
            checkSSH
            checkPAM
            checkSystemConsole
            checkSUaccess
            checkSystemAccounts
            checkBanner
            checkSystem

elif [ "$AUDITMODE" = "1" ]; then
    echo -e "\033[1;36mNOTICE: Audit & Fix Mode On - Make sure you have good backups! \033[m"
            # THIS MODE NEEDS MORE WORK
                echo -n "1.1.1a - Checking if $TMP is on separate partition "
        if [ "$CheckTmpMount" = "0" ]; then
            #TmpMountErr
            err "5" "NOT MOUNTED ON SEPARATE PARTITION"
            skipNotice $TMP

            echo -e " ............... Please mount $TMP partition manually !!"
            echo -e " .............. \033[1;36mChange requires reboot. \033[m"
            # check fstab even though /tmp is not mounted and display warning if /tmp is not mounted but is in /etc/fstab file
                echo -n "1.1.1b - Checking $fstabName for $TMP "
                    if [ "$CheckTmpFstab" = "0" ]; then
                        #FstabNoTmpErr
                        err "6" " $TMP missing from $fstabName"
                        skipNoticeA "Skipping parameter checks for $TMP in $fstabName file."
                    else
                        echo -e " ............... Warning: $TMP is NOT mounted but exist in $fstabName file  "
                        echo -e " ............... Please correct $fstabName or mount $TMP manually. "
                    fi

        elif [ "$CheckTmpMount" = "1" ]; then
            OK "5"

                TmpCheckFix
                FstabTmpCheckFix

        else
            CheckupErr
        fi
            CheckVarFix
            FstabVarCheckFix
            CheckVarTmpFix
            FstabVarTmpCheckFix
            CheckVarLogFix
            FstabVarLogCheckFix
            CheckNodevRemMediaFix
else
    echo -e "\033[1;36mNOTICE: Wrong Mode selected! Please correct the option & re-run the script. \033[m "
    exit 1
fi

}

Begin_Security_Configuration_Benchmark | tee result.txt

AnalyzeResult() {
result="result.txt"
NrQuestions=$(grep "^[0-9]" $result | wc -l)

countPercentage() {
inputType=$1
typeCount=$2
part1=$(expr $typeCount \* 100)
inputPercentage=$(expr $part1 / $NrQuestions)
#echo -e "You have \033[1;36m $typeCount $inputType \033[m which is \033[1;36m $inputPercentage percent \033[m out of \033[1;36m $NrQuestions \033[m checked points."

if [ "$inputType" == "Successes" ]; then
        if [ "$inputPercentage" -eq "95" ]  || [ "$inputPercentage" -gt "95" ]; then
                echo -e "\033[1;36m You have $inputPercentage percentage of OK's, GOOD JOB ! \033[m"
        elif [ "$inputPercentage" -lt "95" ]  && [ "$inputPercentage" -gt "85" ]; then
                echo -e "\033[1;36m You have $inputPercentage percentage of OK's, which is probably OK \033[m"
        elif [ "$inputPercentage" -lt "85" ]  && [ "$inputPercentage" -gt "75" ]; then
                echo -e "\033[1;36m You have $inputPercentage percentage of OK's, but you should improve it \033[m"
        elif [ "$inputPercentage" -lt "75" ]  && [ "$inputPercentage" -gt "65" ]; then
                echo -e "\033[1;36m You have $inputPercentage percentage of OK's, COME ON - you can do better than that! \033[m"
        elif [ "$inputPercentage" -lt "65" ] ; then
                echo -e " \033[1;31m WARNING: You have $inputPercentage percentage of OK's - YOU SHOULD DISCONNECT YOUR BOX FROM THE INTERNET !! \033[m"
                echo -e "\033[1;31m DEFINITELY DO NOT RUN IT AS PRODUCTION BOX \033[m"
        else
                echo "Something went wrong "
        fi
else
echo -e "You have \033[1;36m $typeCount $inputType \033[m which is \033[1;36m $inputPercentage percent \033[m out of \033[1;36m $NrQuestions \033[m checked points."
fi

}
