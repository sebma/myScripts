#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

if ! grep '^\s*DNSStubListenerExtra=.*127.0.0.1:53' /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/* 2>/dev/null -q;then
	sudo mkdir -p /etc/systemd/resolved.conf.d/
	{
		echo [Resolve]
		echo DNSStubListener=yes
		echo DNSStubListenerExtra=udp:127.0.0.1:53
	} | sudo tee /etc/systemd/resolved.conf.d/00-$company-GP.conf
	sudo systemctl restart systemd-resolved.service
fi

if ! grep "^\s*search $searchDomains" /opt/paloaltonetworks/globalprotect/network/config/resolv.conf -q ;then
	echo "search $searchDomains" | sudo tee -a /opt/paloaltonetworks/globalprotect/network/config/resolv.conf
fi
