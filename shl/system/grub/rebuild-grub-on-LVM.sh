#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
#set -o nounset
set -o errexit

$sudo lvs | grep root -q || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

currentRootFS_VGName=$($sudo lvs --noheadings $(findmnt / -o source -n) -o vg_name)
rootFS_VGName=$($sudo lvs | awk  "/$currentRootFS_VGName/{next}"'/root/{print$2;exit}')
rootFS_LVName=$($sudo lvs $rootFS_VGName | awk '/root/{print$1;exit}')

set -x
mount | grep ${rootFS_VGName}-*$rootFS_LVName -q || $sudo mount -v /dev/$rootFS_VGName/$rootFS_LVName /mnt
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
osVGName=$($sudo lvs | awk "/$currentRootFS_VGName/{next}"'/root/{print$2}')
export diskDevice=$(pvs | awk "/$osVGName/"'{print substr($1,1,8)}')
$sudo chroot /mnt bash <<-EOF # mise a la racine du disque monte
	findmnt >/dev/null && mount -av || exit # montage des partitions dans le chroot
	update-grub                   # creation d'un nouveau fichier de configuration : grub.cfg
	[ -d /sys/firmware/efi ] && efiMode=true || efiMode=false
	if $efiMode;then
		efiBootDir=/boot/efi
		mkdir -p $efiBootDir

		case $HOSTTYPE in
			x86_64) target=x86_64-efi;;
		esac

		grub-install --target=$target --efi-directory=$efiBootDir --removable || grub-install --force --target=$target --efi-directory=$efiBootDir --removable # installation de grub
	else
		grub-install $diskDevice || grub-install --force $diskDevice # installation de grub sur le MBR
	fi
	sync
	umount -v /boot/efi $(df | awk '/dev.mapper.*\/[a-z/]+/{print$1}')
EOF
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
