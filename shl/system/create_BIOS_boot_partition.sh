#!/usr/bin/env bash

set -o errexit
set -o nounset

type sudo >/dev/null 2>&1 && sudo="command sudo" || sudo=""
if [ $# != 1 ]
then
        echo "=> Usage : $(basename $0) win7ESPBootFiles.zip" >&2
        exit -1
fi

win7ESPBootFiles="$1"
printf "=> Quel est le device du disque ? : "
read disk
if ! test $disk
then
    echo "=> ERROR: The device name cannot be empty." >&2
    exit 1
fi

echo $disk | grep -q /dev/ 2>/dev/null || disk=/dev/$disk
echo "=> disk = $disk"

printf "=> Quel est le numero de la partition BIOS boot partition ? : "
read bbPartitionNumber
if ! test $bbPartitionNumber
then
    echo "=> ERROR: The E.S.P partition number cannot be empty." >&2
    exit 2
fi

echo "=> bbPartitionNumber = $bbPartitionNumber"

if ! echo $bbPartitionNumber | grep -P "^\d+$"
then
	echo "=> ERROR: The E.S.P partition number must be an integer." >&2
	exit 3
fi

#See this example : https://superuser.com/a/1773065/528454
#$sudo parted -s $disk mktable gpt
#$sudo parted -s $disk mkpart '"BIOS boot partition"' 1Mi 2Mi
$sudo parted -s $disk set $bbPartitionNumber bios_grub on
$sudo parted -s $disk name $bbPartitionNumber '"BIOS boot partition"'
$sudo parted -s $disk print

