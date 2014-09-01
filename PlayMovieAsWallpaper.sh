    #!/bin/bash

    #
    # This script will try to download and autoconfigure packages
    # for displaying video on wallpaper in your linux distrubution.
    # This script assumes that you have bash, wget, mplayer and other basic
    # utilities installed on your system.
    # This script assumes that your user has sudo privilleges.
    # This script may not work on arm and other micro systems.
    #

    ARCH=`uname -m`
    OS=`cat /etc/issue | head -1 | awk -F” ” ‘{print $1}’`
    COMMAND=`which xwinwrap | wc -l`

    if [[ "$EUID" -ne "0" ]]; then
    echo “Please run with sudo”
    exit 1
    else
    if [[ "$COMMAND" -eq "0" ]]; then
    echo -e ‘\033[1;32m' Attempt to download xwinwrap '\033[m'
    wget -q http://tech.shantanugoel.com/resources/downloads/shantz-xwinwrap.zip
    unzip -q shantz-xwinwrap.zip
    if [[ "$ARCH" == "x86_64" ]]; then
    if [[ "$OS" == "Debian" ]] || [[ "$OS" == "Ubuntu" ]]; then
    echo -e ‘\033[1;32m' Attempt to install 64bit Debian based package '\033[m'
    sudo dpkg -i shantz-xwinwrap/x86_64/shantz-xwinwrap_0.3-1_amd64.deb
    echo -e '\033[1;32m' xwinwrap has been installed under `which xwinwrap` '\033[m'
    else
    echo -e '\033[1;32m' Copying 64bit binary into /usr/sbin/ '\033[m'
    sudo cp shantz-xwinwrap/x86_64/xwinwrap /usr/sbin/
    echo -e '\033[1;32m' Installation complete and xwinwrap should be available for usage. '\033[m'
    fi
    else
    if [[ "$OS" == "Debian" ]] || [[ "$OS" == "Ubuntu" ]]; then
    echo -e ‘\033[1;32m’ attempt to install 32bit Debian based package ‘\033[m’
    sudo dpkg -i shantz-xwinwrap/i386/shantz-xwinwrap_0.3-1_i386.deb
    echo -e ‘\033[1;32m’ xwinwrap has been installed under `which xwinwrap` ‘\033[m’
    else
    echo -e ‘\033[1;32m’ Copying 32bit binary into /usr/sbin/ ‘\033[m’
    sudo cp shantz-xwinwrap/i386/xwinwrap /usr/sbin/
    echo -e ‘\033[1;32m’ Installation complete and xwinwrap should be available for usage. ‘\033[m’
    fi
    fi
    else
    echo -e ‘\033[1;32m’ It seems that xwinwrap is already installed and available from: `which xwinwrap` ‘\033[m’
    echo -e ‘\033[1;32m’ If that is incorrect, exit the script and install it manually on your system. ‘\033[m’
    echo -e ‘\033[1;32m’ Otherwise provide path to the movie and enjoy! ‘\033[m’
    read movie
    xwinwrap -ni -fs -s -st -sp -b -nf — mplayer -wid WID $movie -loop 0
    fi
    fi
