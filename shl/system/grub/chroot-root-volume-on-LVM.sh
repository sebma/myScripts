#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
#set -o nounset
set -o errexit

$sudo lvs | grep root -q || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

currentRootFS_VGName=$($sudo lvs --noheadings $(findmnt / -o source -n) -o vg_name)
rootFS_VGName=$($sudo lvs | awk  "/$currentRootFS_VGName/{next}"'/root/{print$2;exit}')
rootFS_LVName=$($sudo lvs $rootFS_VGName | awk '/root/{print$1;exit}')

set -x
if $sudo dumpe2fs /dev/$rootFS_VGName/$rootFS_LVName 2>&1 | grep "Couldn't find valid filesystem superblock." -q;then
	$sudo vgchange -a n $rootFS_VGName
	sleep 1s
	$sudo vgchange -a y $rootFS_VGName
fi
fstype=$($sudo blkid /dev/$rootFS_VGName/$rootFS_LVName -o value -s TYPE)
time $sudo fsck.$fstype -v /dev/$rootFS_VGName/$rootFS_LVName

mount | grep ${rootFS_VGName}-*$rootFS_LVName -q || $sudo mount -v /dev/$rootFS_VGName/$rootFS_LVName /mnt
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
$sudo chroot /mnt bash
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
