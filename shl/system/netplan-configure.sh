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

if [ $# != 2 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile ipaddress/cidr" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
ipaddressCIDR=$2

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
		else
			$sudo netplan set ethernets.$iface.addresses=[$ipaddressCIDR]
			$sudo netplan set ethernets.$iface.link-local=[]
			$sudo netplan set ethernets.$iface.nameservers.addresses=[$DNS_SERVER1,$FallBack_DNS_SERVER]
			$sudo netplan set ethernets.$iface.nameservers.search=[$searchDomains]
			$sudo netplan set ethernets.$iface.routes='[{"to":"default", "via": "'$gateway'"}]'
		fi
	fi
fi
