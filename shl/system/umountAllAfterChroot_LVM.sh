#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName rootFSDevice" >&2
	exit 1
fi

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
set -o nounset

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -wq $path || export PATH=$path:$PATH
done

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}


#rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
#rootFSDevice=/dev/mapper/$rootFSDevice

#fsTypesList="$(printf "ext%d " $(seq 2 4))btrfs f2fs xfs jfs reiserfs nilfs hfs vfat fuseblk"
rootFSDevice=$1
isLVM=$(lsblk -n -o TYPE $rootFSDevice | grep -wq lvm && echo true || echo false)
umount="umount -v"
chrootMntPoint=$(lsblk -n -o MOUNTPOINT $rootFSDevice)
df=$(which df)

if [ -n "$chrootMntPoint" ];then
#	$df -ah | grep $chrootMntPoint && $sudo chroot $chrootMntPoint $umount -a
	set -x
	test -d $chrootMntPoint/boot/efi && mount | grep -q "$chrootMntPoint/.*/efi " && $sudo $umount $chrootMntPoint/boot/efi
#	[ $isLVM = true ] && rootFS_VG=$(sudo lvs --noheadings  -o vg_name $rootFSDevice) && $sudo $umount /dev/$rootFS_VG/*
	$df | grep $chrootMntPoint/  | awk '{print$1}' | xargs -r $sudo $umount
	$df | grep $chrootMntPoint/ || $sudo $umount $chrootMntPoint/{usr,sys/firmware/efi/efivars,sys,proc,dev/pts,dev,run,}
	$df -ah | grep $chrootMntPoint
fi
