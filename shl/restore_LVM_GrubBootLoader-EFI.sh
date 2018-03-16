#!/usr/bin/env sh

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

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
$sudo mkdir -p /mnt/{dev/pts,proc,sys}
mount | grep -q $rootFSDevice || $sudo mount /dev/mapper/$rootFSDevice /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for i in dev dev/pts proc sys ; do $sudo mount --bind /$i /mnt/$i ; done
$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	mount -av                      # montage des partitions dans le chroot
	dpkg -S x86_64-efi/modinfo.sh
#	apt install grub-efi-amd64-bin -y
	test -s /boot/grub/grub.cfg || update-grub # creation d'un nouveau fichier de configuration : grub.cfg
	set -x
	grub-install --target=x86_64-efi --efi-directory=/boot/efi /dev/sda || grub-install --force --target=x86_64-efi --efi-directory=/boot/efi /dev/sda        # installation de grub
	set +x
	sync
	umount -av
EOF
$sudo umount -v /mnt/{sys,proc,dev/pts,dev,}
