#!/usr/bin/env sh

if [ $# = 0 ];then
	OSName=Ubuntu
elif [ $# = 1 ];then
	OSName="$1"
fi

grubenvFS_Type=$(lsblk -n -o type $(df /boot/grub/grubenv | awk '/boot/{printf$1}'))
if [ $grubenvFS_Type = part ];then # https://www.gnu.org/software/grub/manual/grub/html_node/Environment-block.html
	if ! grep GRUB_DEFAULT=.*saved /etc/default/grub -q;then
		sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/" /etc/default/grub && sudo update-grub
	fi
fi

entryName=$(awk -F"'" -v OS=$OSName '$0 ~ OS{printf $2;exit}' /boot/grub/grub.cfg)
if [ -n "$entryName" ];then
	printf "=> At the being, the system is configured to boot to <%s>.\n" "$(grub-editenv - list | cut -d= -f2-)"
	grub-editenv - list | grep "next_entry=$entryName" -q || sudo grub-reboot "$entryName"
	printf "=> Will now boot to <%s>.\n" "$(grub-editenv - list | cut -d= -f2-)"
	echo "=> Rebooting to <$entryName> in 5 seconds ..."
	sleep 5s
	sync
	sudo reboot
	exit
fi
