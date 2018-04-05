#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}
rootFSLogicalVolume=$($sudo lvs | awk '/root/{print$2"-"$1}')
osVGName=$($sudo lvs | awk '/root/{print$2}')
diskDevice=$(pvs | awk "/$osVGName/"'{print substr($1,1,8)}')
#mount -t proc /proc /mnt/proc # Pour que Grub2 trouve /proc/mounts
$sudo mkdir -p /mnt/{dev/pts,proc,sys}
mount | grep -q $rootFSLogicalVolume || $sudo mount /dev/mapper/$rootFSLogicalVolume /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for i in dev dev/pts proc sys ; do $sudo mount --bind /$i /mnt/$i ; done
$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	mount -av                      # montage des partitions dans le chroot
	update-grub                   # creation d'un nouveau fichier de configuration : grub.cfg
	grub-install $diskDevice || grub-install --force $diskDevice        # installation de grub sur le MBR
	sync
	umount -av
EOF
