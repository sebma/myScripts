#!/usr/bin/env sh

if [ $# = 0 ];then
	OSName=Ubuntu
elif [ $# = 1 ];then
	OSName="$1"
fi

entryNumber=$(awk -F: -vOS=$OSName '/^menuentry/{i+=1}/OS/{printf i-1;exit}' /boot/grub/grub.cfg)
entryName=$(awk -F"'" '/OS/{printf $2;exit}' /boot/grub/grub.cfg)

if [ -n "$entryNumber" ];then
	echo "=> Rebooting to Windows in 5 seconds ..."
	sleep 5s
	sudo grub-reboot "$entryName"
	sync
	sudo reboot
	exit
fi
