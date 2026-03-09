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
if   echo $distribID | egrep "centos|rhel|fedora|rocky" -q;then
	isRedHatLike=true
fi

if $isRedHatLike;then
	if ! dnf repolist | grep cuda -q;then
		versionID=$(source /etc/os-release;echo $VERSION_ID)
		rhelMajorVersion=${versionID/.*}
		$sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel$rhelMajorVersion/$(uname -i)/cuda-rhel$rhelMajorVersion.repo
	fi

	$sudo sed -i '/^exclude=/s/^/#/' /etc/yum.conf
	echo "=> Showing graphic(s) controller(s) :"
	\lspci -nnd ::0300
	echo "=> Updating PCI ids ..."
	$sudo update-pciids -q
	echo "=> Showing graphic(s) controller(s) :"
	\lspci -nnd ::0300
	$sudo systemctl stop puppet.service

	if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
		nvidiaDriverVersionNumber=(tr -d '[a-zA-Z-_]' <<< $nvidiaDriverVersion)
		$sudo dnf module enable nvidia-driver:$nvidiaDriverVersion -y || $sudo dnf module switch-to nvidia-driver:$nvidiaDriverVersion -y
		# dnf nvidia-plugin || $sudo dnf install dnf-plugin-nvidia -y
		# dnf versionlock || $sudo dnf install python3-dnf-plugin-versionlock -y # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/version-locking.html
		if [ $nvidiaDriverVersionNumber -gt 515 ];then
			$sudo dnf install nvidia-open -y
			nvidia-smi >/dev/null || $sudo dnf reinstall kmod-nvidia-open-dkms -y
		else
			nvidiaEffectiveDriverVersion=$(dnf info nvidia-driver | awk -F ':| ' '/Version/{print$NF}')
			$sudo dnf install nvidia-driver nvidia-driver-cuda -y
			nvidia-smi >/dev/null || $sudo dnf install kmod-nvidia-$nvidiaEffectiveDriverVersion-$(uname -r | cut -d. -f1-5)-$nvidiaEffectiveDriverVersion-$release -y
		fi
#		$sudo grubby --args="nouveau.modeset=0 rd.driver.blacklist=nouveau" --update-kernel=ALL
		mokutil --sb-state | grep SecureBoot -q && $sudo mokutil --import /var/lib/dkms/mok.pub
	else
		echo "=> There is no $nvidiaDriverVersion available." >&2
		echo "=> Try running this 2 commands :" >&2
		echo $sudo dnf clean metadata >&2
		echo $sudo dnf makecache >&2
		exit 2
	fi
fi
