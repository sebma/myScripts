#!/usr/bin/env bash

scriptBaseName=${0##*/}
#set -o errexit
set -o nounset
type smartctl >/dev/null || exit
sudo="command sudo 2>/dev/null"
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

echo "=> deviceType = $deviceType"
