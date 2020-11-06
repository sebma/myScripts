#!/usr/bin/env bash

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> $scriptBaseName rootFSDevice" >&2
	exit 1
fi

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

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

rootFSDevice=$1
#isLVM=$(lsblk -n -o TYPE $rootFSDevice | grep -wq lvm && echo true || echo false)
umount="umount -v"
chrootMntPoint=$(lsblk -n -o MOUNTPOINT $rootFSDevice)
if [ -n "$chrootMntPoint" ];then
#	df -ah | grep $chrootMntPoint && $sudo chroot $chrootMntPoint $umount -a
	test -d $chrootMntPoint/boot/efi && $sudo $umount $chrootMntPoint/boot/efi
	$sudo $umount $chrootMntPoint/*
	$sudo $umount $chrootMntPoint/{usr,sys/firmware/efi/efivars,sys,proc,dev/pts,dev,run,}
	df -ah | grep $chrootMntPoint
fi
