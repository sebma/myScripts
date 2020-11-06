#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}
rootFS_LV=$($sudo lvs | awk '/root/{print$2"-"$1}')
bootFS_LV=$($sudo lvs | awk '/boot/{print$2"-"$1}')
usrFS_LV=$($sudo lvs | awk '/usr\>/{print$2"-"$1}')
osVGName=$($sudo lvs | awk '/root/{print$2}')

set -x
vgchange -a n $osVGName || exit
vgchange -u $osVGName || exit
#vgscan --mknodes
#vgchange --refresh
#vgchange -a y $osVGName || exit
vgchange -a y || exit
set +x

mount | grep -q $rootFS_LV || $sudo mount -v /dev/mapper/$rootFS_LV /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for special in dev dev/pts proc sys ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done

$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	findmnt >/dev/null && mount -av || exit
	update-grub
#	grub-install /dev/sdd
	sync
	umount -av
EOF
$sudo umount -v /mnt/{usr,sys,proc,dev/pts,dev,}
