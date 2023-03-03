#!/bin/bash
if egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q;then
	if netplan get network | grep ethernets -q;then
		mkdir -pv /etc/netplan/BACKUP/
		cp -piv /etc/netplan/00-installer-config.yaml /etc/netplan/BACKUP/00-installer-config-ORIG.yaml <<< n
		netplan get network.ethernets | awk -F: '/^[^ ]*:$/{print$1}' | while read iface;do
			echo "=> Removing the IP of $iface network interface ..."
			netplan set "network.ethernets.$iface.addresses=null"
		done
		netplan apply
	fi
	echo "=> Re-generating /etc/machine-id and /var/lib/dbus/machine-id ..."
	rm -f /etc/machine-id
	dbus-uuidgen --ensure=/etc/machine-id
	rm -f /var/lib/dbus/machine-id
	dbus-uuidgen --ensure
	echo "=> done."
	echo "=> Re-generating ssh host keys ..."
	for type in dsa ecdsa ed25519 rsa;do
		ssh-keygen -q -f /etc/ssh/ssh_host_${type}_key -N '' -t $type <<< y | grep Generating
	done
	echo "=> done."
fi
systemctl disable firstboot.service
# systemctl mask firstboot.service
