#!/bin/bash

mount -o remount,rw / 2>&1
echo "=> Checking all filesystems at $(date) ..." >&2 | busybox tee fsck_$(date +%Y%m%d).log
grep -v "swap" /etc/fstab | busybox awk '/^\/dev/{print$1" "$3}' | while read FS FSTYPE # car pour utiliser le "awk" standard, il serait necessaire de mounter "/usr"
do
	echo >&2
	echo "=> Checking $FS ..." >&2
	time if [ $FSTYPE = btrfs ];then
		set -x
		btrfsck -p --repair $FS
	else
		set -x
		fsck -p -v $FS
	fi
	set +x
	echo >&2
done 2>&1 | busybox tee -a fsck_$(date +%Y%m%d).log
date | busybox tee -a fsck_$(date +%Y%m%d).log
sync
mount -v -o remount,ro / 2>&1
