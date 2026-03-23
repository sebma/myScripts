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
	echo "=> Showing graphic(s) controller(s) :"
	\lspci -nnd ::0300
	echo "=> Updating PCI ids ..."
	$sudo update-pciids -q
	echo "=> Showing graphic(s) controller(s) :"
	\lspci -nnd ::0300

	$sudo systemctl stop puppet.service
	$sudo sed -i '/^exclude=/s/^/#/' $(readlink -e /etc/yum.conf)
	dnf config-manager --dump | grep ^exclude
	dnf repolist | grep powertools -wq || $sudo dnf config-manager --set-enabled powertools

	if ! dnf repolist | grep cuda -q;then
		rhelMajorVersion=$(source /etc/os-release;echo ${VERSION_ID/.*})
		# See https://docs.rockylinux.org/8/desktop/display/installing_nvidia_gpu_drivers/
		$sudo rm /etc/yum.repos.d/cuda.repo -f
		$sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel$rhelMajorVersion/$(uname -i)/cuda-rhel$rhelMajorVersion.repo
	fi

	if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
		$sudo dnf module enable nvidia-driver:$nvidiaDriverVersion -y || $sudo dnf module switch-to nvidia-driver:$nvidiaDriverVersion -y
		# dnf nvidia-plugin || $sudo dnf install dnf-plugin-nvidia -y
		# dnf versionlock || $sudo dnf install python3-dnf-plugin-versionlock -y # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/version-locking.html
		nvidiaDriverVersionNumber=$(tr -d '[a-zA-Z-_]' <<< $nvidiaDriverVersion)
		if [ $nvidiaDriverVersionNumber -gt 515 ];then
			$sudo dnf install nvidia-open nvidia-driver-cuda -y
			nvidia-smi >/dev/null || $sudo dnf reinstall kmod-nvidia-open-dkms -y
		else
			nvidiaEffectiveDriverVersion=$(dnf info nvidia-driver | awk -F '[: ]' '/Version/{print$NF}')
			$sudo dnf install nvidia-driver nvidia-driver-cuda -y
			release=3
			nvidia-smi >/dev/null || $sudo dnf install kmod-nvidia-$nvidiaEffectiveDriverVersion-$(uname -r | cut -d. -f1-5)-$nvidiaEffectiveDriverVersion-$release.$(uname -r | cut -d. -f6-7) -y
		fi
#		$sudo grubby --args="nouveau.modeset=0 rd.driver.blacklist=nouveau" --update-kernel=ALL
		mokutil --sb-state | grep SecureBoot.enabled -q && $sudo mokutil --import /var/lib/dkms/mok.pub

		# NVIDIA Container Toolkit cf. https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#with-dnf-rhel-centos-fedora-amazon-linux
		$sudo dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
		export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.2-1
		$sudo dnf install -y nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}
	else
		# See https://superuser.com/a/1935617/528454
		echo "=> There is no $nvidiaDriverVersion available in the nvidia-driver DNF modules list." >&2
		echo "=> Try running these commands :" >&2 
		echo $sudo dnf module reset nvidia-driver -y
		echo $sudo dnf clean expire-cache
		echo $sudo dnf makecache
		exit 2
	fi
fi
