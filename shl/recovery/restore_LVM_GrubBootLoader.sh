#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	findmnt >/dev/null && mount -av || exit                      # montage des partitions dans le chroot
	test -s /boot/grub/grub.cfg || update-grub # creation d'un nouveau fichier de configuration : grub.cfg
	grub-install /dev/sda || grub-install --force /dev/sda        # installation de grub sur le MBR
	sync
	umount -av
EOF
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
