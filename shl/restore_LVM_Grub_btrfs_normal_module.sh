#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
$sudo mkdir -p /mnt/{dev/pts,proc,sys}
mount | grep -q $rootFSDevice || $sudo mount -o subvol=@ /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for i in dev dev/pts proc sys ; do $sudo mount --bind /$i /mnt/$i ; done
set +o errexit
$sudo chroot /mnt /bin/bash <<-EOF
	mount -av
	cp -puv /usr/lib/grub/x86_64-efi/*.mod /boot/grub/x86_64-efi/
	sync
	umount -av
EOF
$sudo umount -v /mnt/{sys,proc,dev/pts,dev,}
