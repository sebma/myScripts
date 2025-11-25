#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -wq $path || export PATH=$path:$PATH
done

chrootMntPoint=/mnt/chroot
$sudo mkdir -p $chrootMntPoint
df $chrootMntPoint/proc | grep -q $chrootMntPoint/proc || {
	$sudo mkdir -pv $chrootMntPoint/proc
	$sudo mount -v -t proc /proc $chrootMntPoint/proc
}

for special in dev dev/pts sys run
do
	df $chrootMntPoint/$special | grep -q $chrootMntPoint/$special || {
		$sudo mkdir -pv $chrootMntPoint/$special
		$sudo mount -v --bind /$special $chrootMntPoint/$special
	}
done

if [ -d /sys/firmware/efi ];then
       df $chrootMntPoint/sys/firmware/efi/efivars | grep -q $chrootMntPoint/sys/firmware/efi/efivars || {
		cd $chrootMntPoint/sys/firmware/efi/ && $sudo mkdir -pv efivars
		$sudo mount -v --bind /sys/firmware/efi/efivars $chrootMntPoint/sys/firmware/efi/efivars
       }
fi

$sudo chroot "$@" $SHELL
