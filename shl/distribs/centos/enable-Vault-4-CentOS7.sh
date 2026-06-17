#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	if echo $distribID | egrep "ubuntu" -q;then
		isUbuntuLike=true
	fi
fi

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

if $isRedHatLike;then
	if [ $majorNumber == 7 ];then
		# Disable CentOS7 repos and enable Vault repos
		for repo in base updates extras epel;do yum-config-manager --disable $repo >/dev/null;done
		rpm -Uvh https://vault.centos.org/7.9.2009/updates/x86_64/Packages/centos-release-7-9.2009.2.el7.centos.x86_64.rpm
		unset http_proxy https_proxy
		for repo in C7.9.2009-base C7.9.2009-updates C7.9.2009-extras;do yum-config-manager --enable $repo >/dev/null;done
		yum makecache
		yum repolist
	fi
fi
