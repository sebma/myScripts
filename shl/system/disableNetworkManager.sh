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

if which systemctl >/dev/null 2>&1;then
	if systemctl is-enabled NetworkManager >/dev/null;then
		if $isRedHatLike;then
			$sudo mkdir -v /etc/sysconfig/network-scripts/backups/
			ifList=$(ip -o link | awk -F '[ :]' '/state.UP/{print$3}')
			for iface in $ifList;do
				grep -q "ONBOOT=no" /etc/sysconfig/network-scripts/ifcfg-$iface || $sudo sed -i".$(date +%Y%m%d_%HH%MM%S)" "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-$iface
				sleep 1s
				grep -q "^DNS[12]=" /etc/sysconfig/network-scripts/ifcfg-$iface || $sudo sed -i".$(date +%Y%m%d_%HH%MM%S)" "s/\(DNS[12]=.*\)/#\1/" /etc/sysconfig/network-scripts/ifcfg-$iface
			done
		fi

		grep -q dns /etc/NetworkManager/NetworkManager.conf || $sudo sed -i".$(date +%Y%m%d_%HH%MM%S)" "s/\(plugins=.*ifcfg-rh.*\)/\1\ndns=none/" /etc/NetworkManager/NetworkManager.conf

		if ! env | grep SSH_CONNECTION -q;then #Se lance ssi on le lance a partir de la console
			systemctl is-active NetworkManager >/dev/null || $sudo systemctl start NetworkManager
			ifList=$(nmcli dev | awk '!/wlan/&&/connected/{print$1}')
			for iface in $ifList;do
				$sudo nmcli dev set $iface managed no
				$sudo ifup $iface
			done

			$sudo systemctl stop NetworkManager.service
		fi

		$sudo systemctl disable NetworkManager.service
		$sudo systemctl mask NetworkManager.service
		systemctl -at service | grep NetworkManager.service
	else
		echo "=> NetworkManager.service is already disabled."
		$sudo systemctl mask NetworkManager.service
	fi
fi
