#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

if [ $# != 1 ] && [ $# != 2 ];then
	echo "=> Usage $scriptBaseName filesystemPath [size]" >&2
	exit 1
fi

filesystemPath="$1"
[ $# == 2 ] && size=$2 || size=-1
vgName=$(findmnt -no source "$filesystemPath" | awk -F '[/-]' '{print$4}')
if [ -z "$vgName" ];then
	echo "=> Could not find the LVM VG for the <$filesystemPath> filesystem."
	exit 2
fi

echo "=> vgName = $vgName"
partitionDevicePath=$(sudo vgs --noheadings $vgName -o pv_name | awk '{print$1}')
echo "=> partitionDevicePath = $partitionDevicePath"
diskDevicePath=${partitionDevicePath/[0-9]*/}
disk=$(echo $diskDevicePath | cut -d/ -f3)

diskSizeBefore=$(cat /sys/block/$disk/size)
echo "=> Rescan des disques existants ..."
echo 1 | sudo tee /sys/class/block/sd?/device/rescan >/dev/null
diskSizeAfter=$(cat /sys/block/$disk/size)
if [ $diskSizeAfter == $diskSizeBefore ];then
	echo "=> The $disk disk size has not changed, quitting."
	exit 3
fi

set -x
echo Fix | sudo parted ---pretend-input-tty $diskDevicePath print free
partNum=$(echo $partitionDevicePath | sed "s/.dev.//;s/[a-z]*//")
sudo parted -s $diskDevicePath resizepart $partNum 100%
sudo pvresize $partitionDevicePath
lvName=$(findmnt -no SOURCE "$filesystemPath"" | cut -d- -f2)
echo "=> lvName = $lvName"
if [ $size == -1 ];then
	sudo lvextend -r -l +100%FREE /dev/$vgName/$lvName
else
	sudo lvextend -r -L +$size /dev/$vgName/$lvName
fi
