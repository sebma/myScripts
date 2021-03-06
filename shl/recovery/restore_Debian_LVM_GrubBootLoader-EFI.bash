#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

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
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

set +o errexit
$sudo chroot /mnt $SHELL <<-EOF # mise a la racine du disque monte
	findmnt >/dev/null && mount -av || exit                      # montage des partitions dans le chroot
	dpkg -S x86_64-efi/modinfo.sh
	mokutil --sb-state >/dev/null 2>&1 && apt install -V -y grub-efi-amd64-signed
	host archive.ubuntu.com >/dev/null && apt install -V -y grub-efi-amd64-bin linux-image-generic linux-signed-image-generic
	test -s /boot/grub/grub.cfg || update-grub # creation d'un nouveau fichier de configuration : grub.cfg
	mkdir -p /boot/efi
	set -x
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable || grub-install --force --target=x86_64-efi --efi-directory=/boot/efi --removable # installation de grub
	set +x
	sync
	umount -av
	exit
EOF
$sudo umount -v /mnt/{sys,proc,dev/pts,dev,}
