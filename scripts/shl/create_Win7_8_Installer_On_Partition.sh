#!/usr/bin/env bash

set -o errexit
set -o nounset

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
if [ $# != 1 ]
then
	echo "=> Usage : $(basename $0) Win7DVD_ISOFilePath" >&2
	exit -1
fi

win7DVD_ISOFilePath="$1"
printf "=> Quel est le device du disque ? : "
read disk
if ! test $disk
then
    echo "=> ERROR: The device name cannot be empty." >&2
    exit 1
fi

echo $disk | grep -q /dev/ 2>/dev/null || disk=/dev/$disk
echo "=> disk = $disk"

printf "=> Quel est le numero de la partition qui contiendra l'installer Windows ? : "
read windowsInstallerPartitionNumber
if ! test $windowsInstallerPartitionNumber
then
    echo "=> ERROR: The partition number cannot be empty." >&2
    exit 2
fi

echo "=> windowsInstallerPartitionNumber = $windowsInstallerPartitionNumber"

if ! echo $windowsInstallerPartitionNumber | grep -P "^\d+$"
then
	echo "=> ERROR: The E.S.P partition number must be an integer." >&2
	exit 3
fi

windowsInstallerPartition=$disk$windowsInstallerPartitionNumber
windowsInstallerFS=/mnt/$(basename $windowsInstallerPartition)


$sudo mkdir -p $windowsInstallerFS
$sudo mkdir -p /mnt/iso
$sudo mount $win7DVD_ISOFilePath /mnt/iso
#$sudo mkfs.ntfs $windowsInstallerPartition
$sudo ntfslabel $windowsInstallerPartition Win7Installer
$sudo mount $windowsInstallerPartition $windowsInstallerFS
$(which rsync) -Ptr /mnt/iso/* $windowsInstallerFS/
sync
$sudo umount -v $windowsInstallerPartition $win7DVD_ISOFilePath
$sudo rmdir $windowsInstallerFS
$sudo ms-sys --ntfs $windowsInstallerPartition
$sudo ms-sys --mbr7 $disk
$sudo parted -s $disk set $windowsInstallerPartitionNumber boot on
$sudo parted -s $disk set $windowsInstallerPartitionNumber hidden on
$sudo parted -s $disk print
