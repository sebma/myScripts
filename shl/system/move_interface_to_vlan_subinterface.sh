#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

case $# in
	0) echo "=> Usage : $(basename $0) vlanID";exit 1;;
	1) vlanID=$1;;
	*) echo "=> Usage : $(basename $0) vlanID";exit 1;;
esac

distribID=$(source /etc/os-release;echo $ID)
if echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
fi

if $isRedHatLike;then
	if test -d /proc/net/bonding;then
		iface=$(ls /proc/net/bonding | uniq | head -1)
	else
		iface=$(ip -o a | awk -F '[:| *]' '!/lo\s/&&/inet\s/{print$3}' | uniq | head -1)
	fi

	grep '8021q$' /etc/modules-load.d/*.conf -q || echo 8021q >> /etc/modules-load.d/vlan.conf
	lsmod | grep 8021q -q || modprobe 8021q

	if [ -z "$ipAddress" ];then
		#On deplace l'interface L3 dans le $vlanID
		IPADDR=$(ip -o a sh dev $iface | awk -F '/|\\s*' '/inet\s/{print$4}')
		CIDR=$(ip -o a sh dev $iface | awk -F '/|\\s*' '/inet\s/{print$5}')
		ipPrefix=$(echo $IPADDR | cut -d. -f1-3).
		MTU=$(ip -o l sh dev $iface | awk '/mtu /{print$5}')
	fi
	GATEWAY=$(ip route | awk "/via $ipPrefix/"'{print$3}')
	VLAN=yes

	if [ -n "$GATEWAY" ];then
		DEFROUTE=yes
	else
		DEFROUTE=no
	fi

	cat <<-EOF | tee /etc/sysconfig/network-scripts/ifcfg-$iface.$vlanID
		BOOTPROTO=none
		DEFROUTE=$DEFROUTE
		DEVICE=$iface.$vlanID
		IPADDR=$IPADDR
		GATEWAY=$GATEWAY
		MTU=$MTU
		NAME=$iface.VLAN_$vlanID
		NM_CONTROLLED=no
		ONBOOT=yes
		PREFIX=$CIDR
		TYPE=Ethernet
		USERCTL=no
		VLAN=$VLAN
	EOF

	sed -i.orig '/IPADDR\|GATEWAY\|CIDR\|NETMASK/d' /etc/sysconfig/network-scripts/ifcfg-$iface

	echo "=> Restarting the <network.service> ..."
	time systemctl restart network
fi
