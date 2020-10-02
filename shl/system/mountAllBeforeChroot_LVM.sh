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
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt # montage de celle-ci en remplacant le X par le bon numero de partition

df /mnt/proc | grep -q /mnt/proc || {
	$sudo mkdir -pv /mnt/proc
	$sudo mount -v -t proc /proc /mnt/proc
}
for special in dev dev/pts sys run
do
	df /mnt/$special | grep -q /mnt/$special || {
		$sudo mkdir -pv /mnt/$special
		$sudo mount -v --bind /$special /mnt/$special
	}
done
if [ -d /sys/firmware/efi ];then
       df /mnt/sys/firmware/efi/efivars | grep -q /mnt/sys/firmware/efi/efivars || {
		cd /mnt/sys/firmware/efi/ && $sudo mkdir -pv efivars
		$sudo mount -v --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
       }
fi

$sudo chroot /mnt /bin/bash <<-EOF
	mount | grep " / " | grep -q rw || mount -v -o remount,rw /
	mount -v /boot
	[ -d /sys/firmware/efi ] && mount -v /boot/efi
	mount -v /usr
	mount -v /var
	rm -v /var/lib/apt/lists/lock
	sync
EOF

$sudo chroot /mnt
