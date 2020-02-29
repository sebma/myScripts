#!/bin/bash

type busybox >/dev/null || exit

[ $USER != root ] && echo "=> ERROR [$0] You must run $0 as root." >&2 && exit 2

currentTarget=$(systemctl -t target | egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target')
echo $currentTarget | egrep -q "(recovery|rescue).target" || { echo "=> You must reboot in recovery|rescue mode to run $0." >&2 && exit 3; }

tee="busybox tee"
awk="busybox awk" # car pour utiliser le "awk" standard, il serait necessaire de mounter "/usr"
mount -o remount,rw /
{
	echo "=> hostname = $(hostname)" >&2
	date
	echo "=> The current target is <$currentTarget>."
	echo "=> Unmounting all filesystems ..." >&2
	umount -av
	echo "=> Checking all filesystems at $(date) ..." >&2

	grep -v "swap" /etc/fstab | $awk '/^\/dev/{print$1" "$3}' | while read FS FSTYPE
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
	done

	date;sync
} 2>&1 | $tee fsck_$(date +%Y%m%d).log
mount -v -o remount,ro /
