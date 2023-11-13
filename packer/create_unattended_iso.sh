#!/bin/bash

AUTO_ISO="$1/files/autounattend"

if ! [ -d ${AUTO_ISO} ]; then 
    echo "[-] Unable to find path $AUTO_ISO"
    exit 1
fi

A=$(which xorrisofs)

if [ $? == 1 ]; then
    echo "[-] Unable to find xorrisofs"
    echo "[-] Install xorrisofs:"
    echo "[-]   Debian: sudo apt install xorriso"
    echo "[-]   Fedora: sudo dnf install xorriso"
    exit 1
fi

echo "[+] Build iso ${AUTO_ISO}"
xorrisofs -J -l -R -V "autounatend CD" -f -iso-level 4 -o ./${1}/files/iso/Autounattend_${1}.iso ${AUTO_ISO}

sed "s/<autounattended_cd_name>/files\/iso\/Autounattend_${1}.iso/" windows-autounattend.pkrvars.hcl.sample > $1/$1.auto.pkrvars.hcl

autounattended_hash_value=`sha256sum ./${1}/files/iso/Autounattend_${1}.iso | awk '{print $1}'`

sed -i "s/<autounattended_hash_value>/sha256:$autounattended_hash_value/" $1/$1.auto.pkrvars.hcl