#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
#set -o nounset
set -o errexit

for path in /sbin /bin /usr/sbin /usr/bin
do
	echo $PATH | grep -wq $path || export PATH=$path:$PATH
done

#for special in dev dev/pts proc sys run ; do $sudo mkdir -pv /mnt/$special;$sudo mount -v --bind /$special /mnt/$special ; done
$sudo chroot "$@"
