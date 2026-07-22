#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

if do-release-upgrade -c | grep New.release.*LTS.*available.;then
	sudo apt update
	sudo apt upgrade -Vy
	sudo aptitude upgrade -Vy || sudo apt install -V $(apt list --upgradable 2>/dev/null | awk -F"," "/$(lsb_release -sc)/"'{print$1}') -y
	if ! do-release-upgrade;then
		sudo apt install --reinstall -V ubuntu-keyring
	fi
	do-release-upgrade
	sudo apt autoremove -Vy
fi
