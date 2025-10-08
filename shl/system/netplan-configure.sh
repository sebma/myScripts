#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

scriptBaseName=${0##*/}
if [ $# -lt 2 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile ipaddress/cidr [iface1] [iface2] [iface3] [iface4] ..." >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
ipaddressCIDR=$2
interfaceList=""
if [ $# -gt 2 ];then
	shift 2
	interfaceList="$@"
	interfaceList="${interfaceList// /,}"
fi

#echo "=> interfaceList = $interfaceList"

if $isDebianLike;then
	if $isUbuntuLike && [ $majorNumber -ge 20 ];then
		iface=bond0
		gateway=$(echo $ipaddressCIDR | cut -d. -f1-3).1
		if echo $iface | grep bond -q;then
			$sudo netplan set bonds.$iface.addresses=[$ipaddressCIDR]
			$sudo netplan set bonds.$iface.link-local=[]
			$sudo netplan set bonds.$iface.nameservers.addresses=[$DNS_SERVER1,$FallBack_DNS_SERVER]
			$sudo netplan set bonds.$iface.nameservers.search=[$searchDomains]
			$sudo netplan set bonds.$iface.routes='[{"to":"default", "via": "'$gateway'"}]'
			# CONFIG LACP cf. https://askubuntu.com/a/1287665/426176
			if [ $interfaceList ];then
				$sudo netplan set bonds.$iface.interfaces=[$interfaceList]
				$sudo netplan set bonds.$iface.parameters.mode=802.3ad
				$sudo netplan set bonds.$iface.parameters.lacp-rate=fast
#				$sudo netplan set bonds.$iface.parameters.mii-monitor-interval=100
#				$sudo netplan set bonds.$iface.parameters.transmit-hash-policy=layer2+3
				$sudo modprobe -r bonding
				$sudo netplan apply
			fi
		else
			$sudo netplan set ethernets.$iface.addresses=[$ipaddressCIDR]
			$sudo netplan set ethernets.$iface.link-local=[]
			$sudo netplan set ethernets.$iface.nameservers.addresses=[$DNS_SERVER1,$FallBack_DNS_SERVER]
			$sudo netplan set ethernets.$iface.nameservers.search=[$searchDomains]
			$sudo netplan set ethernets.$iface.routes='[{"to":"default", "via": "'$gateway'"}]'
		fi
	fi
fi
