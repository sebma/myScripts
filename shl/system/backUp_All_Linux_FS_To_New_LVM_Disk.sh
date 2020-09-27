#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	exit 1
fi

destinationDisk=$1
destinationPVPartition=$(sudo fdisk $destinationDisk -l | awk '/Linux LVM/{print$1}')
#destinationVG=$(sudo pvdisplay -C $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationVG=$(sudo pvs $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationLVs=$(sudo lvs $destinationVG -o lv_name | awk 'FNR>1{printf$1" "}')
echo "=> destinationLVs = $destinationLVs"
