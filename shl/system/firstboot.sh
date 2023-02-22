#!/bin/bash
mkdir -pv /etc/netplan/BACKUP/
cp -pv /etc/netplan/00-installer-config.yaml /etc/netplan/BACKUP/00-installer-config-ORIG.yaml
if netplan get network | grep ethernets -q;then
	echo "=> Removing the interface ($iface) IP ..."
	netplan get network.ethernets | awk -F: '/^[^ ]*:$/{print$1}' | while read iface;do
		netplan set "network.ethernets.$iface.addresses=null"
	done
	netplan apply
fi
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A
systemctl disable firstboot.service
#rm -f /etc/systemd/system/firstboot.service
#rm -f /firstboot.sh
