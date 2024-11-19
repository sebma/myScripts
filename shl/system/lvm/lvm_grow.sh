#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

if [ $# != 1 ] && [ $# != 2 ];then
	echo "=> USAGE: $scriptBaseName filesystemPath [newSize]" >&2
	exit 1
fi

filesystemPath="$1"
[ $# == 2 ] && newSize=$2 || newSize=-1
newSizeUpperCase=${newSize^^}

vgName=$(findmnt -no source "$filesystemPath" | awk -F '[/-]' '{print$4}')
if [ -z "$vgName" ];then
	echo "=> ERROR: Could not find the LVM VG for the <$filesystemPath> filesystem." >&2
	exit 2
fi
echo "=> vgName = $vgName"
echo "=> BEFORE: "
df -h "$filesystemPath"

test $(id -u) == 0 && sudo="" || sudo=sudo
partitionDevicePath=$($sudo vgs --noheadings -o pv_name $vgName | awk '{print$1}')
if echo $partitionDevicePath | grep /dev/md -q;then
	echo "=> ERROR: LVM on MD devices is not supported by this script." >&2
	exit 3
fi

echo "=> partitionDevicePath = $partitionDevicePath"
diskDevicePath=${partitionDevicePath/[0-9]*/}
disk=$(echo $diskDevicePath | cut -d/ -f3)

diskSizeBefore=$(cat /sys/block/$disk/size)
echo "=> Re-scanning existing disks for changes (such as size for virtual disks), just in case ..."
echo 1 | $sudo tee /sys/class/block/sd?/device/rescan >/dev/null
echo "=> Re-scanning SCSI hosts for new disks, just in case ..."
echo "- - -" | $sudo tee /sys/class/scsi_host/host*/scan >/dev/null

trap 'echo "=> SIGINT Received, cannot interrupt $scriptBaseName starting from this point, continuing ...";' SIGINT
diskSizeAfter=$(cat /sys/block/$disk/size)
if [ $diskSizeAfter != $diskSizeBefore ];then
	echo "=> Taking the new $diskDevicePath disk size into account."
	echo Fix | $sudo parted ---pretend-input-tty $diskDevicePath print free
	partNum=$(echo $partitionDevicePath | sed "s/.dev.//;s/[a-z]*//")
	echo "=> Upsizing the LVM disk $partitionDevicePath partition."
	$sudo parted -s $diskDevicePath resizepart $partNum 100%
	echo "=> Upsizing the $partitionDevicePath PV LVM structure."
	$sudo pvresize $partitionDevicePath
fi

vgFree=$($sudo vgs --noheadings -o vg_free $vgName | awk '{print toupper($1)}')
newSizeInBytes=$(echo $newSizeUpperCase | numfmt --from=iec --to=none --format=%f)
freeSpaceInBytes=$(echo $vgFree | numfmt --from=iec --to=none --format=%f)
if [ $vgFree == 0 ] || [ $newSizeInBytes -gt $freeSpaceInBytes ];then
	echo "=> ERROR: There is not enough free space on the $disk." >&2
	$sudo vgs $vgName
	exit 4
fi

lvName=$(findmnt -no SOURCE "$filesystemPath" | cut -d- -f2)
echo "=> lvName = $lvName"
if [ $newSize == -1 ];then
	echo "=> Extending $lvName LV to the rest of the remaining space on the $vgName VG."
	$sudo lvextend -r -l +100%FREE /dev/$vgName/$lvName
else
	echo "=> Extending $lvName LV by $newSize."
	$sudo lvextend -r -L +$newSize /dev/$vgName/$lvName
fi
retCode=$?
if [ $retCode != 0 ];then
	echo "=> ERROR: There has been an erreur during the <lvextend> operation." >&2
	exit $retCode
fi

echo "=> AFTER: "
df -h "$filesystemPath"
echo "=> FINISHED."
trap - SIGINT
