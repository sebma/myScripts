#!/bin/bash

tools="awk cut egrep grep head runlevel sed strings tee"
if [ -s /usr/bin/tee ]; then # Si "/usr" est accessible
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas accessible, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

[ $USER != root ] && echo "=> ERROR [$0] You must run $0 as root." >&2 && exit 2

ps --help 2>&1 | $grep -q "error while loading shared libraries" && ps="busybox ps" || ps=$(which ps)
initPath=$($ps -e -o comm= -o pid= | $grep "  *1$" | $cut -d" " -f1)
if [ -n "$initPath" ];then
	initPath=$(which $initPath) #Needed for gentoo and maybe others
	set -o pipefail
	systemType=$($strings $initPath | egrep -o "upstart|sysvinit|systemd" | $head -1 || echo unknown)
else
	exit 1
fi

set +o pipefail
if [ $systemType = systemd ];then
	currentTarget=$(systemctl -t target | $egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target')
	echo $currentTarget | $egrep -q "(recovery|rescue).target" || { echo "=> You must reboot in recovery|rescue mode to run $0." >&2 && exit 3; }
elif [ $systemType = upstart ];then
	runlevelNum=$($runlevel | $awk '{printf$NF}')
fi

fsTypesList="btrfs "$(\ls -1 /sbin/fsck.* | $cut -d. -f2)
fsTypesERE=$(echo $fsTypesList | $sed "s/ /|/g")
fsTypesCSV=$(echo $fsTypesList | $sed "s/ /,/g")
mount -v -o remount,rw /
[ -L /etc/mtab ] || ln -v -s -f /proc/mounts /etc/mtab
storageMounted_FS_List=$(mount | $awk "/\<$fsTypesERE\>/"'{print$1}')

logDir=log
mkdir -p $logDir
logFile=$logDir/umount_$(date +%Y%m%d).log
{
	echo "=> hostname = $(hostname)" >&2
	date
	echo "=> The current systemType is <$systemType>."
	[ $systemType = systemd ] && echo "=> The current target is <$currentTarget>."
	echo "=> Unmounting all storage filesystems ..." >&2
	echo "=> storageMounted_FS_List = $storageMounted_FS_List" >&2
	umount -v -a -t $fsTypesCSV
} 2>&1 | $tee $logFile
mount -v -o remount,ro /
echo "=> Check <$logFile>"
