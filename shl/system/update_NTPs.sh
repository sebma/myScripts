#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

if ! timedatectl show-timesync | egrep "$NTP" -q ;then
	sudo mkdir -p /etc/systemd/timesyncd.conf.d/
	{
	echo [Time]
	echo NTP=$NTP
	echo FallbackNTP=$FallbackNTP
	} | sudo tee /etc/systemd/timesyncd.conf.d/$company-timesyncd.conf
	sudo systemctl restart systemd-timesyncd
	echo "=> Verification du parametrage NTP :"
	timedatectl show-timesync
fi
