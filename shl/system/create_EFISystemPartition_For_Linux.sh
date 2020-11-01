#!/usr/bin/env bash

scriptBaseName=${0##*/}
set -o errexit
set -o nounset

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
if [ $# != 1 ]
then
        echo "=> Usage : $scriptBaseName disk" >&2
        exit -1
fi

disk="$1"
echo $disk | grep -q /dev/ 2>/dev/null || disk=/dev/$disk

if ! [ -b $disk ];then
    echo "=> ERROR: $disk must be a block device." >&2
	exit 1
fi

printf "=> What is the number of the E.S.P partition you wish to create ? : "
read espPartitionNumber
if ! echo $espPartitionNumber | egrep -q "^[0-9]+$"
then
    echo "=> ERROR: The E.S.P partition number must be an integer." >&2
    exit 2
fi

echo "=> espPartitionNumber = $espPartitionNumber"

espPartition=$disk$espPartitionNumber
espFS=/mnt/$(basename $espPartition)

if ! $sudo gdisk -l $disk | grep -qw EF00;then
	$sudo sgdisk -n $espPartitionNumber:0:+260M -t $espPartitionNumber:EF00 -c $espPartitionNumber:"EFI System" $disk
	$sudo gdisk -l $disk

	if [ -b $espPartition ];then
		$sudo mkfs.fat -v -n EFI_SYSTEM -F32 $espPartition
	else
		echo "=> ERROR: Device $espPartition not created." >&2
		exit 3
	fi
	echo
else
	echo "=> INFO : The ESP partition already exits." >&2
#	exit 3
fi

$sudo mkdir -p $espFS
$sudo mount -v $espPartition $espFS

logFile="$HOME/log/copyEFI_System_Partition_to_$(basename $disk)__$(date +%Y%m%d-%HH%M).log"
echo
echo "=> logFile = <$logFile>."
echo

RSYNC_SKIP_COMPRESS_LIST=7z/aac/avi/bz2/deb/flv/gz/iso/jpeg/jpg/mkv/mov/m4a/mp2/mp3/mp4/mpeg/mpg/oga/ogg/ogm/ogv/webm/rpm/tbz/tgz/z/zip
RSYNC_EXCLUSION=$(printf -- "--exclude %s/ " /dev /sys /run /proc /mnt /media)
rsync="$(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION --log-file=$logFile"

cp2FAT32="$rsync --modify-window=1"

$sudo $cp2FAT32 -r /boot/efi/ $espFS/
sync
$sudo umount -v $espPartition
$sudo rmdir $espFS
