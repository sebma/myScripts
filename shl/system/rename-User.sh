#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

if [ $# != 2 ];then
	echo "=> Usage: $scripBaseName : $oldUSER $newUSER" >&2
	exit 1
fi

distribID=$(source /etc/os-release;echo $ID)
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
fi

oldUSER=$1
if $isDebianLike;then
	if id -u $oldUSER >/dev/null;then
		newUSER=$2
		$sudo loginctl terminate-session $(loginctl list-sessions | awk "/$oldUSER/"'{print$1;exit}')
#		$sudo sed -i "s/$oldUSER\>/$newUSER/g" /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/subuid /etc/subgid; $sudo mv /home/$oldUSER /home/$newUSER
		$sudo usermod -l $newUSER -m -d /home/$newUSER $oldUSER && $sudo groupmod -n $newUSER $oldUSER # https://serverfault.com/a/653514/312306
	fi
fi
