#!/bin/sh

echo "=> Checking all filesystems " >&2
busybox awk '/^\/dev/{print$1" "$3}' /etc/fstab | while read FS FSTYPE # car pour utiliser le "awk" standard, il serait necessaire de mounter "/usr"
do
	echo >&2
	echo "=> Checking $FS ..." >&2
	if [ $FSTYPE = btrfs ];then
		set -x
		btrfsck -p --repair $FS
	else
		set -x
		fsck -p -v $FS
	fi
	set +x
	echo >&2
done 2>&1 | busybox tee fsck_$(date +%Y%m%d).log
