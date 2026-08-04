#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	if echo $distribID | egrep "ubuntu" -q;then
		isUbuntuLike=true
	fi
fi

if $isDebianLike;then
	$sudo apt autoremove -V

	$sudo apt update && $sudo apt upgrade -V -y
	if $sudo apt-get upgrade -V -s | grep 'and [^0][0-9]* not upgraded';then
		packagesList=$(apt list --upgradable 2>/dev/null | awk -F"/" "/$(lsb_release -sc)/"'{print$1}' | paste -sd " ")
		packagesRegExp=${packagesList/ /|}
		dpkg -s aptitude &>/dev/null || $sudo apt install -V aptitude -y
		$sudo aptitude install -V $packagesList -y
		if ! $sudo apt install -V $packagesList -y;then
			dpkg -s deborphan &>/dev/null || $sudo apt install -V deborphan -y
			$sudo apt purge -V $(deborphan | egrep "$packagesRegExp")
		fi
	fi
	$sudo apt autoremove -V
fi
