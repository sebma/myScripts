#!/usr/bin/env sh

entryNumber=$(awk -F: '/^menuentry/{i+=1}/Windows/{printf i-1;exit}' /boot/grub/grub.cfg)

if [ -n "$entryNumber" ];then
	echo "=> Rebooting to Windows in 5 seconds ..."
	sleep 5s
	sudo grub-reboot $entryNumber
	sync
	sudo reboot
	exit
fi
