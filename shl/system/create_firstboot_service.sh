#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(which sudo)

if egrep "vmware|virtal" /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name -q;then
#	Taken from https://askubuntu.com/a/1327781
	cat << EOF | $sudo tee /etc/systemd/system/firstboot.service
[Unit]
Description=One time boot script
[Service]
Type=simple
ExecStart=/firstboot.sh
[Install]
WantedBy=multi-user.target
EOF

	cat <<-EOF | $sudo tee /firstboot.sh
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
EOF

	# $sudo systemctl enable firstboot.service # A saisir juste AVANT le clonage de la VM
	$sudo chmod +x /firstboot.sh
fi
