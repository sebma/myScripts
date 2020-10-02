#!/usr/bin/env bash

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

rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
if mount | grep -q $rootFSDevice;then
	mnt=$(lsblk -n -o MOUNTPOINT /dev/mapper/$rootFSDevice)
#	df -ah | grep $mnt && $sudo chroot $mnt /bin/umount -av
	$sudo umount -v $mnt/{usr,sys/firmware/efi/efivars,sys,proc,dev/pts,dev,run,}
	df -ah | grep $mnt
fi
