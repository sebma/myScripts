#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

sudo apt autoremove -V
if ! do-release-upgrade -c;then
	sudo apt install --reinstall -V ubuntu-keyring
fi

if do-release-upgrade -c | grep New.release.*LTS.*available.;then
	sudo apt update && sudo apt upgrade -Vy
	if sudo apt-get upgrade -V -s | grep 'and [^0][0-9]* not upgraded';then
		packagesList=$(apt list --upgradable 2>/dev/null | awk -F"/" "/$(lsb_release -sc)/"'{print$1}' | paste -sd " ")
		packagesRegExp=${packagesList/ /|}
		sudo aptitude install -V $packagesList -y
		if ! sudo apt install -V $packagesList -y;then
			sudo apt purge -V $(deborphan | egrep "$packagesRegExp")
		fi
	fi

	do-release-upgrade
fi
sudo apt autoremove -V
