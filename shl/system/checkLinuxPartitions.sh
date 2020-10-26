#!/bin/bash

tools="awk cut egrep grep head runlevel sed strings tee"
if [ -s /usr/bin/tee ]; then # Si "/usr" est accessible
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas accessible, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

[ $USER != root ] && echo "=> ERROR [$0] You must run $0 as root." >&2 && exit 2

initPath=$(\ps -p 1 -o cmd= | $cut -d" " -f1)
set -o pipefail
systemType=$($strings $initPath | $egrep -o "upstart|sysvinit|systemd" | $head -1 || echo unknown)
set +o pipefail

if [ $systemType = systemd ];then
	currentTarget=$(systemctl -t target | $egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target')
	echo $currentTarget | $egrep -q "(recovery|rescue).target" || { echo "=> You must reboot in recovery|rescue mode to run $0." >&2 && exit 3; }
elif [ $systemType = upstart ];then
	mount -v -r /var
	runlevelNum=$($runlevel | $awk '{printf$NF}')
	umount -v /var
fi

fsTypesList="btrfs "$(\ls -1 /sbin/fsck.* | $cut -d. -f2)
fsTypesERE=$(echo $fsTypesList | $sed "s/ /|/g")
fsTypesCSV=$(echo $fsTypesList | $sed "s/ /,/g")
mount -v -o remount,rw /
[ -L /etc/mtab ] || ln -v -s -f /proc/mounts /etc/mtab
storageMounted_FS_List=$(mount | $awk "/\<$fsTypesERE\>/"'{print$1}')

logDir=log
mkdir -p $logDir
logFile=$logDir/fsck_$(date +%Y%m%d).log
{
	echo "=> hostname = $(hostname)" >&2
	date
	echo "=> The current systemType is <$systemType>."
	[ $systemType = systemd ] && echo "=> The current target is <$currentTarget>."
	echo "=> Unmounting all storage filesystems ..." >&2
	echo "=> storageMounted_FS_List = $storageMounted_FS_List" >&2
	umount -v -a -t $fsTypesCSV
	echo "=> Checking all filesystems at $(date) ..." >&2

	grep -v "swap" /etc/fstab | $awk '/^\/dev/{print$1" "$3}' | while read FS FSTYPE
	do
		echo >&2
		echo "=> Checking the $FSTYPE $FS filesystem ..." >&2
		time if [ $FSTYPE = btrfs ];then
			btrfsck -p --repair $FS
		else
			fsck -C -p -v $FS
		fi || continue
		set +x
		echo >&2
	done
	echo >&2

	date;sync
} 2>&1 | $tee $logFile
mount -v -o remount,ro /
set -o
echo "=> Check <$logFile>"
