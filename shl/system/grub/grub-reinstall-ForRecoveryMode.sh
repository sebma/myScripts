#!/bin/bash

tools="awk cut egrep grep head runlevel sed strings tee"
if [ -s /usr/bin/tee ]; then # Si "/usr" est accessible
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas accessible, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

[ $USER != root ] && echo "=> ERROR [$0] You must run $0 as root." >&2 && exit 2

initName=$(\ps -p 1 -o cmd= | $cut -d" " -f1)
initPath=$(type -P $initName)
set -o pipefail
systemType=$($strings $initPath | $egrep -o "upstart|sysvinit|systemd|launchd" | $head -1 || echo unknown)
set +o pipefail

if [ $systemType = systemd ];then
	currentTarget=$(systemctl -t target | $egrep -o '^(emergency|rescue|graphical|multi-user|recovery|friendly-recovery).target')
	echo $currentTarget | $egrep -q "(recovery|rescue).target" || { echo "=> You must reboot in recovery|rescue mode to run $0." >&2 && exit 3; }
elif [ $systemType = upstart ];then
	:
fi

mount | grep -q "/usr " || mount -v -r /usr
mount -v /boot
mount -v /boot/efi
[ -d /sys/firmware/efi ] && efiDirectory=$(mount | awk '/\/efi /{print$3}') && grub-install --removable --efi-directory=$efiDirectory || grub-install /dev/sda
sync
umount -v /boot/efi /boot /usr
