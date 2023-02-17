#!/usr/bin/env bash

declare {isDebian,isRedHat}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
    isRedHatLike=true
	sudo=""
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	sudo=sudo
fi
test $(id -u) == 0 && sudo=""

if $isRedHatLike;then
	grep "NOZEROCONF\s*=\s*yes" /etc/sysconfig/network -q || echo 'NOZEROCONF=yes # Disables APIPA' | $sudo tee -a /etc/sysconfig/network

	echo "=> Restarting the <network.service> ..."
	time systemctl restart network.service
fi
ip route | grep 169.254.
