#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName destinationDisk" >&2
	exit 1
fi

df=$(which df)
destinationDisk=$1
destinationPVPartition=$(sudo fdisk $destinationDisk -l | awk '/Linux LVM/{print$1}')
#destinationVG=$(sudo pvdisplay -C $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationVG=$(sudo pvs $destinationPVPartition -o vg_name | awk 'END{print$1}')
destinationLVList=$(sudo lvs $destinationVG -o lv_name | awk 'FNR>1{print$1}' | sort -u | paste -sd' ')
echo "=> destinationLVList = $destinationLVList"
fsRegExp="\<(ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs|hfs|vfat|fuseblk)\>"
sourceFilesystemsList=$(df -T | egrep -vw "/media|/mnt|/tmp" | awk "/$fsRegExp/"'{print$NF}' | sort -u | paste -sd' ')
usrSourceFS=$($df /usr | grep -v ^Filesystem | cut -d" " -f1)
isLVM=$(lsblk -n $usrSourceFS -o TYPE | grep -qw lvm && echo yes || echo no)
[ isLVM = yes ] && sourceVG=$(echo $usrSourceFS | sed -E "s,/dev/|mapper.|,,g;s,[/-].*,,")
echo "=> sourceFilesystemsList = $sourceFilesystemsList"
rsync="time $(which rsync) -x -uth -P -z --skip-compress=$RSYNC_SKIP_COMPRESS_LIST $RSYNC_EXCLUSION"
cp2ext234="$rsync -ogpuv -lSH"
cp2FAT32="$rsync --modify-window=1"
destinationDir=/mnt/destinationVGDir
sudo mkdir -v $destinationDir/
sudo mount -v /dev/$destinationVG/$(echo $destinationLVList | grep root) $destinationDir/
echo sudo $cp2ext234 -r -x / $destinationDir/
test -d $destinationDir/etc/ || sudo mkdir -v $destinationDir/etc/ 
test -f $destinationDir/etc/fstab
