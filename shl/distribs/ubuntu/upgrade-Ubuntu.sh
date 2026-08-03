#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

if ! do-release-upgrade;then
	sudo apt install --reinstall -V ubuntu-keyring
fi

if do-release-upgrade -c | grep New.release.*LTS.*available.;then
	sudo apt update && sudo apt upgrade -Vy
	if sudo apt-get upgrade -V -s | grep 'and [^0][0-9]* not upgraded';then
		sudo aptitude install -V $(apt list --upgradable 2>/dev/null | awk -F"/" "/$(lsb_release -sc)/"'{print$1}') -y
		sudo apt install -V $(apt list --upgradable 2>/dev/null | awk -F"/" "/$(lsb_release -sc)/"'{print$1}') -y || exit
	fi

	do-release-upgrade
	sudo apt autoremove -Vy
fi
