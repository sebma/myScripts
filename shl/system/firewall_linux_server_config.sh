#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
# majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

if $isDebianLike;then
	test $(id -u) == 0 && sudo="" || sudo=sudo

#	$sudo ufw app list
	$sudo sed -i "s/IPV6.*/IPV6=no/" /etc/default/ufw

	localNetwork=$(ip -4 route show dev $(ip -4 route show default | awk '{print$5}') | awk '!/default/{print$1}')
	for ip in $localNetwork $bastionIP;do
		$sudo ufw allow from $ip to any app OpenSSH
		$sudo ufw allow from $ip to any port 1022 proto tcp comment "do-release-upgrade alternate SSH port"
	done

	for ip in $networkManagerStations;do
		$sudo ufw allow from $ip to any port snmp proto udp
	done
	$sudo ufw allow from $glpiSERVER to any port 62354 proto tcp comment "GLPI-Agent"

	$sudo ufw enable
	$sudo ufw status numbered
fi
