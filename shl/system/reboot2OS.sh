#!/usr/bin/env sh

if [ $# = 0 ];then
	OSName=Ubuntu
elif [ $# = 1 ];then
	OSName="$1"
fi

if ! grep GRUB_DEFAULT=.*saved /etc/default/grub -q;then
	sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/" /etc/default/grub
	sudo update-grub
fi

#entryNumber=$(awk -F: -v OS=$OSName '/^menuentry/{i+=1}$0 ~ OS{printf i-1;exit}' /boot/grub/grub.cfg)
entryName=$(awk -F"'" -v OS=$OSName '$0 ~ OS{printf $2;exit}' /boot/grub/grub.cfg)

if [ -n "$entryName" ];then
	printf "=> At the being, the system is configured to boot to <%s> by default.\n" "$(grub-editenv - list | cut -d= -f2-)"
	grub-editenv - list | grep "next_entry=$entryName" -q || sudo grub-reboot "$entryName"
	printf "=> Will now boot to <%s> by default.\n" "$(grub-editenv - list | cut -d= -f2-)"
	echo "=> Rebooting to <$entryName> in 5 seconds ..."
	sleep 5s
	sync
	sudo reboot
	exit
fi
