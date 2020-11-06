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
if mount | grep -q $rootFSDevice;then
	chrootMntPoint=$(lsblk -n -o MOUNTPOINT $rootFSDevice)
#	df -ah | grep $chrootMntPoint && $sudo chroot $chrootMntPoint /bin/umount -av
	$sudo umount -v $chrootMntPoint/{usr,sys/firmware/efi/efivars,sys,proc,dev/pts,dev,run,}
	$sudo umount -v $chrootMntPoint/*
	df -ah | grep $chrootMntPoint
fi
