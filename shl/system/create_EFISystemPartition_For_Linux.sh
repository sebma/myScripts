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
	cat<<-EOF | $sudo parted $disk
		print
		mkpart "EFI System" fat32 1M 256M
		set $espPartitionNumber boot on
		set $espPartitionNumber esp on
		set $espPartitionNumber hidden on
		print
	EOF

	$sudo mkfs.fat -n EFI_SYSTEM -F32 $espPartition
else
	echo "=> INFO : The ESP partition already exits." >&2
#	exit 3
fi

$sudo mkdir -p $espFS
$sudo mount -v $espPartition $espFS

sync
$sudo umount -v $espPartition
$sudo rmdir $espFS
