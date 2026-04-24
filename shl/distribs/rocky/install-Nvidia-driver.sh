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

	$sudo systemctl disable --now puppet.service
	# $sudo sed -i '/^exclude=/s/^/#/' $(readlink -e /etc/yum.conf)
	$sudo sed -i.bak '/^proxy=/s/^/#/' $(readlink -e /etc/yum.conf)
	dnf config-manager --dump | grep ^exclude
	dnf repolist | grep powertools -wq || $sudo dnf config-manager --set-enabled powertools
	dnf repolist | grep epel -wq || $sudo dnf install epel-release -y

	if ! dnf repolist | grep cuda -q;then
		rhelMajorVersion=$(source /etc/os-release;echo ${VERSION_ID/.*})
		# See https://docs.rockylinux.org/8/desktop/display/installing_nvidia_gpu_drivers/
		#$sudo rm /etc/yum.repos.d/cuda.repo -f
		dnf repolist | grep 'cuda\s.*cuda$' -q && $sudo dnf config-manager --disable cuda
		$sudo dnf remove *nvidia* cuda-drivers -y
		$sudo sed -i.bak 's/pkgs.dyn.su/pkgs.sysadmins.ws/' /etc/yum.repos.d/raven.repo # cf. https://git.sysadmins.ws/pkgs/raven/commit/3a0b578c3e#diff-25c0edd698ac12b47c5e2548b587db23904aac24
		dnf repolist | grep cuda-rhel$rhelMajorVersion-$(uname -i) -q || $sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel$rhelMajorVersion/$(uname -i)/cuda-rhel$rhelMajorVersion.repo
	fi

	dnf clean expire-cache # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html
	if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
		$sudo dnf clean expire-cache
		$sudo dnf module reset nvidia-driver -y
		$sudo dnf module enable nvidia-driver:$nvidiaDriverVersion -y
		# dnf nvidia-plugin || $sudo dnf install dnf-plugin-nvidia -y
		# dnf versionlock || $sudo dnf install python3-dnf-plugin-versionlock -y # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/version-locking.html
		nvidiaDriverVersionNumber=$(tr -d '[a-zA-Z-_]' <<< $nvidiaDriverVersion)
		if [ $nvidiaDriverVersionNumber -lt 515 ];then
			$sudo dnf install nvidia-driver nvidia-driver-cuda -y
		else
			if   echo $nvidiaDriverVersion | grep -- "-open$" -q;then
				$sudo dnf install nvidia-open kmod-nvidia-open-dkms nvidia-driver-cuda -y --allowerasing

				#nvidiaEffectiveDriverVersion=$(dnf info nvidia-driver | awk -F '[: ]' '/Version/{print$NF}')
				#release=3
				#nvidia-smi >/dev/null || $sudo dnf install kmod-nvidia-$nvidiaEffectiveDriverVersion-$(uname -r | cut -d. -f1-5)-$nvidiaEffectiveDriverVersion-$release.$(uname -r | cut -d. -f6-7) -y
			elif echo $nvidiaDriverVersion | grep -- "-dkms$" -q;then
				$sudo dnf install nvidia-driver kmod-nvidia-latest-dkms nvidia-driver-cuda -y --allowerasing

				#nvidiaEffectiveDriverVersion=$(dnf info nvidia-driver | awk -F '[: ]' '/Version/{print$NF}')
				#release=3
				#nvidia-smi >/dev/null || $sudo dnf install kmod-nvidia-$nvidiaEffectiveDriverVersion-$(uname -r | cut -d. -f1-5)-$nvidiaEffectiveDriverVersion-$release.$(uname -r | cut -d. -f6-7) -y
			fi
		fi

		$sudo reboot
		nvidia-smi >/dev/null || $sudo dnf reinstall kmod-nvidia-*-dkms -y
		$sudo dnf install nvidia-container-toolkit -y --allowerasing
		$sudo systemctl restart docker.service
		$sudo dnf install cuda cuda-toolkit -y --allowerasing
		# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Rocky&target_version=8&target_type=rpm_network
		# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#meta-packages
		# https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html
		nvidia-smi | grep Version
		# https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/post-installation-actions.html

#		$sudo grubby --args="nouveau.modeset=0 rd.driver.blacklist=nouveau" --update-kernel=ALL
		mokutil --sb-state | grep SecureBoot.enabled -q && $sudo mokutil --import /var/lib/dkms/mok.pub

		# NVIDIA Container Toolkit cf. https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#with-dnf-rhel-centos-fedora-amazon-linux
		# $sudo dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
		# export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.2-1
		# $sudo dnf install -y nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        # libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}
	else
		# See https://superuser.com/a/1935617/528454
		echo "=> There is no $nvidiaDriverVersion available in the nvidia-driver DNF modules list." >&2
		echo "=> Try running these commands :" >&2 
		echo dnf clean expire-cache
		echo $sudo dnf clean expire-cache
		exit 2
	fi
fi
