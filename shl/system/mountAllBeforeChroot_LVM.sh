#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

if [ $# != 1 ];then
	echo "=> $0 rootFSDevice" >&2
	exit 1
else
	rootFSDevice=$1
fi

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -wq $path || export PATH=$path:$PATH
done

$sudo lvs | grep -q root || {
	$sudo pvscan
	$sudo vgscan
	$sudo lvscan
}

#rootFSDevice=$($sudo lvs | awk '/root/{print$2"-"$1}')
#rootFSDevice=/dev/mapper/$rootFSDevice

chrootMntPoint=/mnt/chroot
$sudo mkdir -p $chrootMntPoint

mount | grep -q $rootFSDevice || $sudo mount -v $rootFSDevice $chrootMntPoint # montage de celle-ci en remplacant le X par le bon numero de partition

df $chrootMntPoint/proc | grep -q $chrootMntPoint/proc || {
	test -d $chrootMntPoint/proc || $sudo mkdir -v $chrootMntPoint/proc
	$sudo mount -v -t proc /proc $chrootMntPoint/proc
}

df $chrootMntPoint/run | grep -q $chrootMntPoint/run || {
	test -d $chrootMntPoint/run || $sudo mkdir -v $chrootMntPoint/run
	$sudo mount -v -t tmpfs tmpfs $chrootMntPoint/run
}

set -x
#for special in dev dev/pts sys run
for special in dev dev/pts sys
do
	df $chrootMntPoint/$special | grep -q $chrootMntPoint/$special || {
		$sudo mkdir -pv $chrootMntPoint/$special
		$sudo mount -v --bind /$special $chrootMntPoint/$special
	}
done
set +x

if [ -d /sys/firmware/efi ];then
       df $chrootMntPoint/sys/firmware/efi/efivars | grep -q $chrootMntPoint/sys/firmware/efi/efivars || {
		cd $chrootMntPoint/sys/firmware/efi/ && $sudo mkdir -pv efivars
		$sudo mount -v --bind /sys/firmware/efi/efivars $chrootMntPoint/sys/firmware/efi/efivars
       }
fi

#test -e /var/lib/apt/lists/lock && rm -v /var/lib/apt/lists/lock && sync

$sudo chroot $chrootMntPoint mount >/dev/null 2>&1 && mount="mount -v" || mount="busybox mount -v"
$sudo chroot $chrootMntPoint $SHELL <<-EOF
	$mount | grep -q "/usr " || $mount /usr
EOF

test -n "$sudo" && sudo="$sudo -H" # Pour eviter que le .profile de $USER ne soit lance
$sudo chroot $chrootMntPoint $SHELL
