#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName nvidiaDriverVersion" >&2
	exit 1
fi

nvidiaDriverVersion=$1
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

declare {isDebian,isRedHat,isAlpine}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
elif echo $distribID | egrep "alpine" -q;then
	isAlpineLike=true
fi

if $isRedHatLike;then
	if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
		nvidiaDriverVersionNumber=(tr -d '[a-zA-Z-_]' <<< $nvidiaDriverVersion)
		$sudo dnf module enable $nvidiaDriverVersion -y
		if [ $nvidiaDriverVersionNumber -gt 515 ];then
			$sudo dnf install nvidia-open -y
			nvidia-smi >/dev/null || $sudo dnf reinstall kmod-nvidia-open-dkms -y
		else
			$sudo dnf install nvidia-driver nvidia-driver-cuda -y
			nvidia-smi >/dev/null || $sudo dnf reinstall kmod-nvidia-driver-$(uname -r) -y
		fi
#		$sudo grubby --args="nouveau.modeset=0 rd.driver.blacklist=nouveau" --update-kernel=ALL
		mokutil --sb-state | grep SecureBoot -q && $sudo mokutil --import /var/lib/dkms/mok.pub
	else
		echo "=> There is no $nvidiaDriverVersion available." >&2
		exit 2
	fi
fi
