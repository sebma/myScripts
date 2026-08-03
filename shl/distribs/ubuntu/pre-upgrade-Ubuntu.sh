#!/usr/bin/env bash

set -u
scriptBaseName=${0/*\//}

distribID=$(source /etc/os-release;echo $ID)
majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
	if echo $distribID | egrep "ubuntu" -q;then
		isUbuntuLike=true
	fi
fi

if ! env | grep http_proxy;then
	echo "=> ERROR : You need to define http_proxy and export variables first." >&2
	echo "=> and run script with \"sudo -E\"."
	exit 1
fi

grep ::proxy /etc/apt/apt.conf.d/*proxy

# mkdir ~/ImageMagick-6/ && cp -piv /etc/ImageMagick-6/policy.xml ~/ImageMagick-6/policy.xml
# dpkg -l imagemagick-6-common &>/dev/null && sudo apt purge imagemagick-6-common -Vy && sudo apt autoremove -V

dpkg -l open-vm-tools &>/dev/null && sudo apt install open-vm-tools -Vy

################## DEPLACEMENT ES CONF DANS DES SOUS REPERTOIRES #####################
sudo mkdir -p /etc/systemd/timesyncd.conf.d/
if egrep 'NTP=[0-9.]+' /etc/systemd/timesyncd.conf -q 2>/dev/null;then
	sudo mv -v /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.d/
	sudo apt -V install --reinstall -o Dpkg::Options::="--force-confask,confnew,confmiss" systemd-timesyncd
	sudo systemctl restart systemd-timesyncd.service
fi

sudo mkdir -p /etc/snmp/snmpd.conf.d/
if sudo grep -i '^agentAddress' /etc/snmp/snmpd.conf -q 2>/dev/null;then
	sudo mv -v /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.d/
	sudo apt -V install --reinstall -o Dpkg::Options::="--force-confask,confnew,confmiss" snmpd
	sudo systemctl restart snmpd.service
fi

sudo apt install -V aptitude deborphan ripgrep htop dfc pv ncdu fd-find jq -y
[ $majorNumber -ge 22 ] && sudo apt install -V plocate -y

[ $http_proxy  ] && sudo snap get system proxy.http  -l 2>/dev/null | grep proxy.http  -wq || time sudo snap set system proxy.http=$http_proxy
[ $https_proxy ] && sudo snap get system proxy.https -l 2>/dev/null | grep proxy.https -wq || time sudo snap set system proxy.https=$https_proxy
sudo snap get system proxy
snap debug connectivity

sudo grep '^\s*Defaults:%sudo env_keep.*https_proxy' /etc/sudoers /etc/sudoers.d/* 2>/dev/null -q || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"' | sudo tee -a /etc/sudoers.d/proxy_env
test -s /etc/sudoers.d/proxy_env && sudo chmod 640 /etc/sudoers.d/proxy_env

if ! which ppa-purge >/dev/null 2>&1;then
	sudo apt install -V ppa-purge -y
fi

ls /etc/apt/sources.list.d/ | awk -F- "/$(lsb_release -sc).list$/"'{print$1"/"$3}' | while read repo;do
	sudo ppa-purge ppa:$repo -y
	sudo add-apt-repository ppa:$repo -r -y
done
