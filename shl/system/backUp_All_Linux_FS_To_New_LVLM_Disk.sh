#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName" >&2
	exit 1
fi

destinationDisk=$1
destinationPVPartition=$(sudo fdisk $destinationDisk -l | awk -F"/| " '/Linux LVM/{print$3}')
destinationVG=$(sudo pvs /dev/$destinationPVPartition -o vg_name | awk '!/^\s+VG\s+$/{print$1}')
