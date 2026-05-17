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

	if ! dnf repolist | grep epel -w -q;then
		$sudo dnf install epel-release -y
		$sudo dnf makecache
	fi

	# See https://elrepo.org/wiki/doku.php?id=nvidia-detect
	if ! dnf repolist | grep elrepo -w -q;then
		$sudo dnf install elrepo-release -y
		$sudo dnf makecache
		$sudo dnf install nvidia-detect -y
		# $sudo dnf remove elrepo-release -y
		# See https://github.com/elrepo/packages/tree/master/nvidia-detect#readme
		nvidia-detect
		nvidia-detect -h
		nvidia-detect -v
		nvidia-detect -x
		# $sudo dnf install $(nvidia-detect)
	fi

	rhelMajorVersion=$(source /etc/os-release;echo ${VERSION_ID/.*})
	if [ $rhelMajorVersion -le 8 ];then
		if ! dnf repolist | grep powertools -w -q;then
			$sudo dnf config-manager --enable powertools
			$sudo dnf makecache
		fi
	else
		if ! dnf repolist | grep crb -w -q;then
			$sudo dnf config-manager --set-enabled crb
			$sudo dnf makecache
		fi
	fi
	# cf. https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html#preparation
	
	if ! dnf repolist | grep cuda -q;then
		# See https://docs.rockylinux.org/8/desktop/display/installing_nvidia_gpu_drivers/
		$sudo rm /etc/yum.repos.d/cuda.repo -f
		$sudo dnf remove *nvidia* cuda-drivers -y
		if dnf repolist | grep cuda-rhel -q;then
			$sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel$rhelMajorVersion/$(uname -i)/cuda-rhel$rhelMajorVersion.repo
			$sudo dnf makecache
		fi
	fi

	$sudo sed -i.bak 's/pkgs.dyn.su/pkgs.sysadmins.ws/' /etc/yum.repos.d/raven.repo # cf. https://git.sysadmins.ws/pkgs/raven/commit/3a0b578c3e#diff-25c0edd698ac12b47c5e2548b587db23904aac24

	dnf clean expire-cache # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html
	dnf makecache
	if dnf module list nvidia-driver | grep $nvidiaDriverVersion -q;then
		$sudo dnf clean expire-cache
		$sudo dnf module reset nvidia-driver -y
		$sudo dnf module enable nvidia-driver:$nvidiaDriverVersion -y
		# dnf nvidia-plugin || $sudo dnf install dnf-plugin-nvidia -y
		# dnf versionlock || $sudo dnf install python3-dnf-plugin-versionlock -y # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/version-locking.html
		nvidiaDriverVersionNumber=$(tr -d '[a-zA-Z-_]' <<< $nvidiaDriverVersion)
		echo "=> See https://download.nvidia.com/XFree86/Linux-x86_64/$nvidiaDriverVersionNumber.142/README/supportedchips.html"
		if [ $nvidiaDriverVersionNumber -lt 515 ];then
			$sudo dnf install nvidia-driver nvidia-driver-cuda -y
		else
			if   echo $nvidiaDriverVersion | grep -- "-open$" -q;then
				$sudo dnf install nvidia-open kmod-nvidia-open-dkms nvidia-driver-cuda -y --allowerasing
			elif echo $nvidiaDriverVersion | grep -- "-dkms$" -q;then
				$sudo dnf install nvidia-driver kmod-nvidia-latest-dkms nvidia-driver-cuda -y --allowerasing
				# $sudo dnf install cuda-drivers kmod-nvidia-latest-dkms nvidia-driver-cuda -y --allowerasing # cf. https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html#driver-installation
			fi
		fi

		$sudo reboot

		# Si on boot sur un nouveau kernel, il faut re-installer le packet kmod-nvidia-latest-dkms || kmod-nvidia-open-dkms
		which nvidia-smi >/dev/null && ! nvidia-smi >/dev/null && $sudo dnf reinstall kmod-nvidia-*-dkms -y

		# PLUS SIMPLE :
		if ! dnf repolist | grep docker-ce -q;then
			$sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo # https://docs.docker.com/engine/install/centos/#install-using-the-repository
			$sudo dnf makecache
		fi

		$sudo dnf install docker-ce docker-compose-plugin -y
		$sudo systemctl enable --now docker.service
		$sudo dnf install nvidia-container-toolkit -y
		$sudo systemctl restart docker.service

		# NECESSAIRE ? :
		$sudo dnf install cuda cuda-toolkit -y # See https://docs.nvidia.com/cuda/cuda-installation-guide-linux/#meta-packages

		# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Rocky&target_version=8&target_type=rpm_network
		# https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/rocky-linux.html
		# https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/post-installation-actions.html

		nvidia-smi | grep Version
		cat /proc/driver/nvidia/version
		$(echo /usr/local/cuda-*/bin/nvcc | head -1) --version

		# nouveau driver disable :
		grep -w nouveau /etc/modprobe.conf /etc/modprobe.d/ -r -q 2>/dev/null || echo -e 'blacklist nouveau\noptions nouveau modeset=0\noptions nvidia_drm modeset=1' | $sudo tee -a /etc/modprobe.d/nvidia.conf >/dev/null
		$sudo grubby --args="nouveau.modeset=0 rd.driver.blacklist=nouveau" --update-kernel=ALL
		
		mokutil --sb-state | grep SecureBoot.enabled -q && $sudo mokutil --import /var/lib/dkms/mok.pub
	else
		# See https://superuser.com/a/1935617/528454
		echo "=> There is no $nvidiaDriverVersion available in the nvidia-driver DNF modules list." >&2
		echo "=> Try running these commands :" >&2 
		echo dnf clean expire-cache
		echo $sudo dnf clean expire-cache
		exit 2
	fi
fi
