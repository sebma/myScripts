#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

if efibootmgr &> /dev/null
then
	efiMode=true
else
	efiMode=false
fi

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}
rootFSLogicalVolume=$($sudo lvs | awk '/root/{print$2"-"$1}')
osVGName=$($sudo lvs | awk '/root/{print$2}')
diskDevice=$(pvs | awk "/$osVGName/"'{print substr($1,1,8)}')

mount | grep -q $rootFSLogicalVolume || $sudo mount /dev/mapper/$rootFSLogicalVolume /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	mkdir -p /boot/efi
	findmnt >/dev/null && mount -av || exit                      # montage des partitions dans le chroot
	update-grub                   # creation d'un nouveau fichier de configuration : grub.cfg
	if $efiMode
	then
		grub-install --target=x86_64-efi --efi-directory=/boot/efi $diskDevice || grub-install --force --target=x86_64-efi --efi-directory=/boot/efi $diskDevice        # installation de grub
	else
		rmdir /boot/efi
		grub-install $diskDevice || grub-install --force $diskDevice        # installation de grub sur le MBR
	fi
	sync
	umount -v /boot/efi $(df | awk '/dev.mapper.*\/[a-z/]+/{print$1}')
EOF
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
