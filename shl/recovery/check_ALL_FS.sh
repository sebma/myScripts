#!/bin/bash

tools="awk cut egrep grep sed tee"
if mount | grep -q "/usr "; then
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas monte, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

[ $USER != root ] && echo "=> ERROR [$0] You must run $0 as root." >&2 && exit 2

currentTarget=$(systemctl -t target | $egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target')
echo $currentTarget | $egrep -q "(recovery|rescue).target" || { echo "=> You must reboot in recovery|rescue mode to run $0." >&2 && exit 3; }

fsTypesList="btrfs "$(\ls -1 /sbin/fsck.* | $cut -d. -f2)
fsTypesERE=$(echo $fsTypesList | $sed "s/ /|/g")
fsTypesCSV=$(echo $fsTypesList | $sed "s/ /,/g")
storageMounted_FS_List=$(mount | $awk "/\<$fsTypesERE\>/"'{print$1}')

logDir=log
mkdir -p $logDir
logFile=$logDir/fsck_$(date +%Y%m%d).log
mount -o remount,rw /
{
	echo "=> hostname = $(hostname)" >&2
	date
	echo "=> The current target is <$currentTarget>."
	echo "=> Unmounting all storage filesystems ..." >&2
	echo "=> storageMounted_FS_List = $storageMounted_FS_List" >&2
	umount -v -a -t $fsTypesCSV
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
			fsck -t nobtrfs -C -A -v $FS
		fi
		set +x
		echo >&2
	done
	echo >&2

	date;sync
} 2>&1 | $tee $logFile
mount -v -o remount,ro /
echo "=> Check <$logFile>"
