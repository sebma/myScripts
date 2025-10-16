#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

scriptBaseName=${0##*/}
if [ $# != 2 ];then
	echo "=> Usage: $scripBaseName : oldUSER newUSER" >&2
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
		$sudo loginctl terminate-session $(loginctl list-sessions | awk "/$oldUSER/"'{print$1;exit}')

		newUSER=$2
		oldMount=$(grep $oldUSER /etc/passwd | grep -v /home/$oldUSER | cut -d: -f6)
		[ $oldMount ] && grep "^[^#]/$oldUSER" /etc/fstab -q && $sudo umount -v $oldMount
#		$sudo sed -i "s/$oldUSER\>/$newUSER/g" /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/subuid /etc/subgid; $sudo mv /home/$oldUSER /home/$newUSER
		# https://serverfault.com/a/653514/312306
		$sudo groupmod -n $newUSER $oldUSER && $sudo usermod -l $newUSER -m -d /home/$newUSER $oldUSER
		$sudo sed -i "s/$oldUSER\>/$newUSER/g" /etc/subuid /etc/subgid /etc/ssh/sshd_config
		[ $oldMount ] && $sudo sed -i "s/$oldUSER\>/$newUSER/g" /etc/fstab && newMount=${oldUSER/$newUSER/} && $sudo mount -v $newMount
	fi
fi
