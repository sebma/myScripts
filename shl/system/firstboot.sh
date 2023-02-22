#!/bin/bash
if egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q;then
	if netplan get network | grep ethernets -q;then
		mkdir -pv /etc/netplan/BACKUP/
		cp -pv /etc/netplan/00-installer-config.yaml /etc/netplan/BACKUP/00-installer-config-ORIG.yaml
		netplan get network.ethernets | awk -F: '/^[^ ]*:$/{print$1}' | while read iface;do
			echo "=> Removing the interface ($iface) IP ..."
			netplan set "network.ethernets.$iface.addresses=null"
		done
		netplan apply
	fi
fi
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A
systemctl disable firstboot.service
#rm -f /etc/systemd/system/firstboot.service
#rm -f /firstboot.sh
