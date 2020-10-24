#!/usr/bin/env bash

scriptBaseName=${0##*/}
#set -o errexit
set -o nounset
type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
diskDevice=""
os=$(uname -s)

if [ $# = 0 ]
then
    [ $os = Linux  ] && diskDevice=sda
    [ $os = Darwin ] && diskDevice=disk0
else
    [ "$1" = "-h" ] && {
        echo "=> Usage: $scriptBaseName [disk device name]" >&2
        exit 1
    } || diskDevice=$1
fi

if ! echo $diskDevice | grep -q /dev/; then
    diskDevice=/dev/$diskDevice
fi

deviceType=$(test $(</sys/block/${diskDevice/*\//}/queue/rotational) = 0 && echo SSD || echo HDD)

if [ $deviceType != SSD ];then
	echo "[$scriptBaseName] => ERROR: $diskDevice is not a SSD."
	exit 1
fi

echo "=> deviceType = $deviceType"
#grep -q noatime /etc/fstab || $sudo sed -i "/^\/dev/s/defaults/defaults,noatime/" /etc/fstab
grep -q noatime /etc/fstab || $sudo sed -i "s/defaults/defaults,noatime/" /etc/fstab
