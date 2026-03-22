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
mount | grep ${rootFS_VGName}-*$rootFS_LVName -q || $sudo mount -v /dev/$rootFS_VGName/$rootFS_LVName /mnt
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
$sudo chroot /mnt bash
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
