#!/usr/bin/env bash

scriptBaseName=${0##*/}
#set -o errexit
set -o nounset
type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
diskDevice=""
os=$(uname -s)

[ $os = Linux  ] && diskDevice=sda
[ $os = Darwin ] && diskDevice=disk0

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

if grep -q noatime /etc/fstab;then
	echo "[$scriptBaseName] => INFO: noatime is already enabled"
else
	echo "[$scriptBaseName] => INFO: Enabling noatime ..."
#	$sudo sed -i "/^\/dev/s/defaults/defaults,noatime/" /etc/fstab
	$sudo sed -i "s/defaults/defaults,noatime/" /etc/fstab
	echo "[$scriptBaseName] => INFO: DONE. You need to reboot."
fi

if [ -s /etc/cron.weekly/fstrim ];then
	echo "[$scriptBaseName] => INFO: FSTRIM is already enabled :"
	echo
	set -x
	cat /etc/cron.weekly/fstrim
elif [ -s /lib/systemd/system/fstrim.timer ];then
	echo "[$scriptBaseName] => INFO: FSTRIM is already enabled :"
	echo
	set -x
	cat /lib/systemd/system/fstrim.timer
	cat /lib/systemd/system/fstrim.service
	systemctl status fstrim.timer
else
	echo "[$scriptBaseName] => WARNING: FSTRIM is not enabled."
fi

set +x
