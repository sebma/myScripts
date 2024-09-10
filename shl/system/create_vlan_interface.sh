#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false

case $# in
	0) echo "=> Usage : $(basename $0) vlanID ipAddress/cidr";exit 1;;
	2) vlanID=$1;ipAddress=${2/\/*/};cidr=$(echo $2 | awk -F/ '{print$2}');;
	*) echo "=> Usage : $(basename $0) vlanID ipAddress/cidr";exit 1;;
esac

if [ $# == 2 ] && [ -z "$cidr" ];then
	echo "=> ERROR : The cidr cannot be empty." >&2
	echo "=> Usage : $(basename $0) vlanID ipAddress/cidr" >&2
	exit 2
fi

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

	if [ -n "$ipAddress" ];then
		#On cree une nouvelle interface dans le $vlanID
		IPADDR=$ipAddress
		CIDR=$cidr
		ipPrefix=$(echo $ipAddress | cut -d. -f1-3).
		MTU=$(< /sys/class/net/$iface/mtu)
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

	echo "=> Restarting the <network.service> ..."
	time systemctl restart network.service
fi
