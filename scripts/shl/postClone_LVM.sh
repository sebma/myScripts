#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && sudo=$(which sudo) || sudo=""
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

$sudo mkdir -p /mnt/{dev/pts,proc,sys}
mount | grep -q $rootFS_LV || $sudo mount -v /dev/mapper/$rootFS_LV /mnt          # montage de celle-ci en remplacant le X par le bon numero de partition
for i in dev dev/pts proc sys ; do $sudo mount -v --bind /$i /mnt/$i ; done
$sudo chroot /mnt /bin/bash <<-EOF # mise a la racine du disque monte
	mount -av
	update-grub
#	grub-install /dev/sdd
	sync
	umount -av
EOF
