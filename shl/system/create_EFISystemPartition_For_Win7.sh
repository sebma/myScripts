#!/usr/bin/env bash

scriptBaseName=${0##*/}
set -o errexit
set -o nounset

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
if [ $# != 1 ]
then
        echo "=> Usage : $scriptBaseName win7ESPBootFiles.zip" >&2
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

if ! $sudo gdisk -l $disk | grep -qw EF00;then
	$sudo sgdisk -n $espPartitionNumber:0:+512M -t $espPartitionNumber:EF00 -c $espPartitionNumber:"EFI System" $disk
	$sudo gdisk -l $disk

	if [ -b $espPartition ];then
		$sudo mkfs.fat -v -n EFI_SYSTEM -F32 $espPartition
	else
		echo "=> ERROR: Device $espPartition not created." >&2
		exit 3
	fi
	echo
fi

$sudo dosfslabel $espPartition "EFI_System"

$sudo mkdir -p $espFS
$sudo mount $espPartition $espFS
$sudo mkdir -p $espFS/EFI/Microsoft/Boot
$sudo unzip -d $espFS/EFI/Microsoft/Boot/ $win7ESPBootFiles 
sync
ls -l $espFS/EFI/Microsoft/Boot
$sudo umount $espPartition
$sudo rmdir $espFS
