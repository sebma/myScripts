#!/bin/bash
mkdir -pv /etc/netplan/BACKUP/
cp -pv /etc/netplan/00-installer-config.yaml /etc/netplan/BACKUP/00-installer-config-ORIG.yaml
iface=$(netplan get network.ethernets | awk -F: '/^[^ ]*:$/{print$1;exit}')
echo "=> Removing the first interface ($iface) IP ..."
#yq -i ".network.ethernets.$iface.addresses=[]" /etc/netplan/00-installer-config.yaml
netplan set "network.ethernets.$iface.addresses=null"
netplan apply
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
systemctl disable firstboot.service
#rm -f /etc/systemd/system/firstboot.service
#rm -f /firstboot.sh
