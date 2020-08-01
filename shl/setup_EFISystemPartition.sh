#!/usr/bin/env bash

set -o errexit
set -o nounset

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
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

printf "=> Quel est le numero de la partition E.S.P ? : "
read espPartitionNumber
if ! test $espPartitionNumber
then
    echo "=> ERROR: The E.S.P partition number cannot be empty." >&2
    exit 2
fi

echo "=> espPartitionNumber = $espPartitionNumber"

if ! echo $espPartitionNumber | grep -P "^\d+$"
then
	echo "=> ERROR: The E.S.P partition number must be an integer." >&2
	exit 3
fi

espPartition=$disk$espPartitionNumber
espFS=/mnt/$(basename $espPartition)

#$sudo parted $disk mkpart primary fat32 1 256
#$sudo mkfs.fat -F32 $espPartition
$sudo dosfslabel $espPartition "SYSTEM"
$sudo parted -s $disk set $espPartitionNumber boot on
$sudo parted -s $disk set $espPartitionNumber esp on
$sudo parted -s $disk set $espPartitionNumber hidden on
$sudo parted -s $disk name $espPartitionNumber '"EFI System"'
printf "C\n$espPartitionNumber\nEFI System\nW\nY\n" | $sudo gdisk $disk
$sudo parted -s $disk print

$sudo mkdir -p $espFS
$sudo mount $espPartition $espFS
$sudo mkdir -p $espFS/EFI/Microsoft/Boot
$sudo unzip -d $espFS/EFI/Microsoft/Boot/ $win7ESPBootFiles 
sync
ls -l $espFS/EFI/Microsoft/Boot
$sudo umount $espPartition
$sudo rmdir $espFS
