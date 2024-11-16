#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

if [ $# != 1 ] && [ $# != 2 ];then
	echo "=> USAGE: $scriptBaseName filesystemPath [size]" >&2
	exit 1
fi

filesystemPath="$1"
[ $# == 2 ] && size=$2 || size=-1
vgName=$(findmnt -no source "$filesystemPath" | awk -F '[/-]' '{print$4}')
if [ -z "$vgName" ];then
	echo "=> ERROR: Could not find the LVM VG for the <$filesystemPath> filesystem."
	exit 2
fi

echo "=> vgName = $vgName"
partitionDevicePath=$(sudo vgs --noheadings $vgName -o pv_name | awk '{print$1}')
echo "=> partitionDevicePath = $partitionDevicePath"
diskDevicePath=${partitionDevicePath/[0-9]*/}
disk=$(echo $diskDevicePath | cut -d/ -f3)

diskSizeBefore=$(cat /sys/block/$disk/size)
echo "=> Re-scanning existing disks for changes (such as size for virtual disks), just in case ..."
echo 1 | sudo tee /sys/class/block/sd?/device/rescan >/dev/null
echo "=> Re-scanning SCSI hosts for new disks, just in case ..."
echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan >/dev/null

trap 'echo "=> SIGINT Received, cannot interrupt $scriptBaseName starting from this point, continuing ...";' SIGINT
diskSizeAfter=$(cat /sys/block/$disk/size)
set -x
if [ $diskSizeAfter != $diskSizeBefore ];then
	echo "=> Taking the new $diskDevicePath disk size into account."
	echo Fix | sudo parted ---pretend-input-tty $diskDevicePath print free
	partNum=$(echo $partitionDevicePath | sed "s/.dev.//;s/[a-z]*//")
	echo "=> Upsizing the LVM disk $partitionDevicePath partition."
	sudo parted -s $diskDevicePath resizepart $partNum 100%
	echo "=> Upsizing the $partitionDevicePath PV LVM structure."
	sudo pvresize $partitionDevicePath
fi

vgFree=$(sudo vgs --noheadings $vgName -o vg_free | awk '{print$1}')
if [ $vgFree == 0 ]
	echo "=> ERROR: There is not enough free space on the $disk."
	exit 3
fi

lvName=$(findmnt -no SOURCE "$filesystemPath" | cut -d- -f2)
echo "=> lvName = $lvName"
if [ $size == -1 ];then
	echo "=> Extending $lvName LV to the rest of the remaining space on the $vgName VG."
	sudo lvextend -r -l +100%FREE /dev/$vgName/$lvName
else
	echo "=> Extending $lvName LV by $size."
	sudo lvextend -r -L +$size /dev/$vgName/$lvName
fi
echo "=> FINISHED."
trap - SIGINT
