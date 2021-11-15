#!/usr/bin/env sh

if [ $# = 0 ];then
	OSName=Ubuntu
elif [ $# = 1 ];then
	OSName="$1"
fi

grep GRUB_DEFAULT=.*saved /etc/default/grub -q || sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/" /etc/default/grub

#entryNumber=$(awk -F: -v OS=$OSName '/^menuentry/{i+=1}$0 ~ OS{printf i-1;exit}' /boot/grub/grub.cfg)
entryName=$(awk -F"'" -v OS=$OSName '$0 ~ OS{printf $2;exit}' /boot/grub/grub.cfg)

if [ -n "$entryName" ];then
	echo "=> Rebooting to <$entryName> in 5 seconds ..."
	sleep 5s
	sudo grub-reboot "$entryName"
	sync
	sudo reboot
	exit
fi
