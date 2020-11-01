#!/usr/bin/env bash

scriptBaseName=${0##*/}
#set -o errexit
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

printf "=> What is the number of the LVM partition you wish to create ? : "
read lvmPartitionNumber
if ! echo $lvmPartitionNumber | egrep -q "^[0-9]+$"
then
    echo "=> ERROR: The LVM partition number must be an integer." >&2
    exit 2
fi

echo "=> lvmPartitionNumber = $lvmPartitionNumber"
echo

lvmPartition=$disk$lvmPartitionNumber
lvmFS=/mnt/$(basename $lvmPartition)
diskModelName=$(sudo smartctl -i $disk | awk '/Device Model:/{$1=$2="";gsub("  ","");gsub(" ","_");print}')
diskSerialNumber=$(sudo smartctl -i $disk | awk '/Serial Number:/{$1=$2="";gsub("  ","");gsub(" ","_");print}')

if ! $sudo gdisk -l $disk | grep -qw 8E00;then
#	cat <<-EOF | $sudo parted $disk
#	print
#	mkpart $diskModelName-$diskSerialNumber ext2 256MB -1
#	set $lvmPartitionNumber lvm on
#	print
#	EOF

	$sudo sgdisk -n $lvmPartitionNumber:0:0 -t $lvmPartitionNumber:8E00 -c $lvmPartitionNumber:$diskModelName-$diskSerialNumber $disk
	$sudo gdisk -l $disk

	echo
	if [ -b $lvmPartition ];then
		$sudo pvcreate -v $lvmPartition
	else
		echo "=> ERROR: Device $lvmPartition not created." >&2
		exit 3
	fi
	echo
else
	echo "=> INFO : This LVM partition already exits." >&2
	echo >&2
#	exit 3
fi

$sudo parted $disk print
