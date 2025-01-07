#!/bin/bash
if [ $(id -u) != 0 ];then
    echo "=> This script must be run as root."
    exit 1
fi

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	if echo $distribID | egrep "ubuntu" -q;then
		isUbuntuLike=true
	fi
fi

if egrep -i "vmware|virtal" /sys/class/dmi/id/sys_vendor -q;then
	initName=$(ps -p 1 -o comm=)
 	localectl set-locale LANG=en_US.UTF-8
	if ! grep "^\s*kernel.dmesg_restrict\s*=\s*0" /etc/sysctl.conf /etc/sysctl.d/*.conf -q;then
		echo kernel.dmesg_restrict=0 | tee -a /etc/sysctl.conf
		systemctl restart systemd-sysctl.service
	fi
	if $isDebianLike;then
		update-ca-certificates --fresh
		sed -i 's/^ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
		dpkg-reconfigure sysstat -f noninteractive
		if netplan get network | grep ethernets -q;then
			mkdir -pv /etc/netplan/BACKUP/
			cp -piv /etc/netplan/00-installer-config.yaml /etc/netplan/BACKUP/00-installer-config-ORIG.yaml <<< n
			netplan get network.ethernets | awk -F: '/^[^ ]*:$/{print$1}' | while read iface;do
				echo "=> Removing the IP of $iface network interface ..."
				netplan set "network.ethernets.$iface.addresses=null"
			done
			netplan apply
		fi
		if $isUbuntuLike;then
			rm -fv /var/lib/ubuntu-release-upgrader/release-upgrade-available
		fi
 	elif $isRedHatLike;then
		update-ca-trust extract
		: # TO DO
	fi

	echo "=> Re-generating /etc/machine-id and /var/lib/dbus/machine-id ..."
 	# echo -n > /etc/machine-id
	rm -f /etc/machine-id
	dbus-uuidgen --ensure=/etc/machine-id
	rm -f /var/lib/dbus/machine-id
	dbus-uuidgen --ensure
 	[ $initName == systemd ] && systemd-machine-id-setup
	echo "=> done."
	echo "=> Re-generating ssh host keys ..."
	for type in dsa ecdsa ed25519 rsa;do
		ssh-keygen -q -f /etc/ssh/ssh_host_${type}_key -N '' -t $type <<< y | grep Generating
	done
	echo "=> done."
	systemctl start syslog.socket
	syslogSERVER=x.y.z.t1
	grep $syslogSERVER /etc/rsyslog.conf /etc/rsyslog.d/* -q || echo "*.* @$syslogSERVER" | tee -a /etc/rsyslog.d/$companyNAME-rsyslog.conf
	systemctl restart rsyslog
fi
systemctl disable firstboot.service
# systemctl mask firstboot.service
