#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

test $(id -u) == 0 && sudo="" || sudo=sudo
if $isDebianLike;then
	$sudo apt install -V ufw -y
	$sudo ufw enable
	$sudo ufw status
fi
