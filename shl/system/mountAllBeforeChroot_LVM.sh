#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -q $path || export PATH=$path:$PATH
done

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done
$sudo chroot /mnt /bin/bash
