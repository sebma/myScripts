#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

grep ::proxy /etc/apt/apt.conf.d/*proxy

# mkdir ~/ImageMagick-6/ && cp -piv /etc/ImageMagick-6/policy.xml ~/ImageMagick-6/policy.xml
dpkg -l imagemagick-6-common && sudo apt purge imagemagick-6-common -Vy

################## DEPLACEMENT ES CONF DANS DES SOUS REPERTOIRES #####################
sudo mkdir -p /etc/systemd/timesyncd.conf.d/
if egrep 'NTP=[0-9.]+' /etc/systemd/timesyncd.conf -q 2>/dev/null;then
	sudo mv -v /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/
	sudo apt -V install --reinstall -o Dpkg::Options::="--force-confask,confnew,confmiss" systemd-timesyncd
	sudo systemctl restart systemd-timesyncd.service
fi

sudo mkdir -p /etc/snmp/snmpd.conf.d/
if grep -i '^agentAddress' /etc/snmp/snmpd.conf -q 2>/dev/null;then
	sudo mv -v /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/
	sudo apt -V install --reinstall -o Dpkg::Options::="--force-confask,confnew,confmiss" snmpd
	sudo sed -i "/^agent[aA]ddress/s/^/#/" /etc/snmp/snmpd.conf
	sudo systemctl restart snmpd.service
fi

sudo apt install -V aptitude plocate ripgrep htop dfc pv ncdu fd-find jq -y

[ $http_proxy ] &&  sudo snap get system proxy.http  2>/dev/null | grep proxy.http -q  || time sudo snap set system proxy.http=$http_proxy
[ $https_proxy ] && sudo snap get system proxy.https 2>/dev/null | grep proxy.https -q || time sudo snap set system proxy.https=$https_proxy
env | grep http_proxy -q || sudo snap get system proxy
snap debug connectivity

sudo grep '^\s*Defaults:%sudo env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* 2>/dev/null -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"' | sudo tee -a /etc/sudoers.d/proxy_env
test -s /etc/sudoers.d/proxy_env && sudo chmod 640 /etc/sudoers.d/proxy_env

if ! which ppa-purge >/dev/null 2>&1;then
	sudo apt install -V ppa-purge -y
fi

egrep -h "deb\s+http://ppa.launchpad.net/" /etc/apt/sources.list.d/*-$(lsb_release -sc).list | awk -F/ '{print$4"/"$5}' | while read repo;do
	sudo ppa-purge ppa:$repo -y
	sudo add-apt-repository ppa:$repo -r -y
done

grep -h URI.*https://ppa.launchpadcontent.net/ /etc/apt/sources.list.d/*-$(lsb_release -sc).sources | uniq | awk -F/ '{print$4"/"$5}'| while read repo;do
	sudo ppa-purge ppa:$repo -y
	sudo add-apt-repository ppa:$repo -r -y
done
