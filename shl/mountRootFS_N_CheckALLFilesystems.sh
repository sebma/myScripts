#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root" && sudo=$(which sudo) || sudo=""
#set -o nounset
#set -o errexit

[ $# != 1 ] && {
	echo "=> ERROR : $0 diskDeviceName" >&2
	exit 1
}

diskDeviceName=$1

$sudo lvs | grep -q root || {
	$sudo pvscan
	LinuxVGName=$(LANG=C $sudo vgscan | awk -F'"' '/Found volume/{print$2}')
	for vg in $LinuxVGName
	do
		$sudo vgchange -a y $vg
	done
	$sudo lvscan
}
rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
#mount -t proc /proc /mnt/proc # Pour que Grub2 trouve /proc/mounts
$sudo fsck /dev/mapper/$rootFSDevice # Checks the root filesystem
$sudo mkdir -pv /mnt/dev/pts /mnt/proc /mnt/sys
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for i in dev dev/pts proc sys ; do $sudo mount --bind /$i /mnt/$i ; done
$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	mv -v /etc/fstab /etc/fstab.BACKUP
	sed "/\<1$/s/^/#/" /etc/fstab.BACKUP > /etc/fstab # On ne recheckera pas le root filesystem
	sync
	fsck -a || fsck -a # check all other filesystems
	mv -v /etc/fstab.BACKUP /etc/fstab
	sync
	mount /usr # pour la commande awk ou cut
	for FS in $(fsck -N /dev/mapper/* 2>/dev/null | awk '/btrfs/{printf$NF" "}'); do test -n "$FS" && btrfsck --repair $FS; done # checks only btrfs filesystems
	umount -l /usr
	umount /usr
	true # A cause du "set -o errexit"
EOF
$sudo umount -v /mnt/sys /mnt/proc /mnt/dev/pts /mnt/dev /mnt
