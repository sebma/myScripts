#!/usr/bin/env bash

scriptBaseName=${0##*/}
#set -o errexit
set -o nounset
type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
diskDevice=""
os=$(uname -s)

if [ $# = 0 ]
then
	[ $os = Linux  ] && diskDevice=sda
	[ $os = Darwin ] && diskDevice=disk0
else
	[ "$1" = "-h" ] && {
		echo "=> Usage: $scriptBaseName [disk device name]" >&2
		exit 1
	} || diskDevice=$1
fi

if ! echo $diskDevice | grep -q /dev/; then
    diskDevice=/dev/$diskDevice
fi

isSSD=$(test $(</sys/block/${diskDevice/*\//}/queue/rotational) = 0 && echo true || echo false)
if $isSSD;then
	echo "[$scriptBaseName] => INFO: $diskDevice is a SSD."
else
	echo "[$scriptBaseName] => ERROR: $diskDevice is not a SSD."
	exit 1
fi

rootDevice=$(findmnt -n -c / -o SOURCE)
if echo $rootDevice | grep -q /dev/mapper/;then
	rootVG=$($sudo \lvs --noheadings $rootDevice -o vg_name | tr -d " ")
	rootDisk=$($sudo \vgs --noheadings $rootVG -o pv_name | tr -d " ")
else
	rootDisk=$rootDevice
fi

if ! echo $rootDisk | grep -q $diskDevice;then
	echo "[$scriptBaseName] => ERROR: The root partition is not on $diskDevice."
	exit 2
fi

if grep -q noatime /etc/fstab;then
	echo "[$scriptBaseName] => INFO: noatime is already enabled in </etc/fstab>."
else
	echo "[$scriptBaseName] => INFO: Enabling noatime in </etc/fstab> ..."
#	$sudo sed -i "/^\/dev/s/defaults/defaults,noatime/" /etc/fstab
	$sudo sed -i "s/defaults/defaults,noatime/" /etc/fstab
	echo "[$scriptBaseName] => WARNING: DONE. You need to reboot or remount all partitions manually with the command 'mount -o remount,noatime /mount_point_path'."
fi

if [ -s /etc/cron.weekly/fstrim ];then
	echo "[$scriptBaseName] => INFO: FSTRIM is already enabled in </etc/cron.weekly/fstrim>."
	echo
elif [ -s /lib/systemd/system/fstrim.timer ];then
	echo "[$scriptBaseName] => INFO: FSTRIM is already enabled :"
	echo
	systemctl status fstrim.timer fstrim.service
	echo
	echo "=> To view more details type :"
	echo systemctl cat fstrim.timer fstrim.service
else
	echo "[$scriptBaseName] => WARNING: FSTRIM is not enabled."
fi

set +x
