#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -wq $path || export PATH=$path:$PATH
done

df /mnt/proc | grep -q /mnt/proc || {
	$sudo mkdir -pv /mnt/proc
	$sudo mount -v -t proc /proc /mnt/proc
}
for special in dev dev/pts sys run
do
	df /mnt/$special | grep -q /mnt/$special || {
		$sudo mkdir -pv /mnt/$special
		$sudo mount -v --bind /$special /mnt/$special
	}
done
if [ -d /sys/firmware/efi ];then
       df /mnt/sys/firmware/efi/efivars | grep -q /mnt/sys/firmware/efi/efivars || {
		cd /mnt/sys/firmware/efi/ && $sudo mkdir -pv efivars
		$sudo mount -v --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
       }
fi

$sudo chroot "$@"
