#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

test $(id -u) == 0 && sudo="" || sudo=sudo

echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)

if [ $osFamily == Linux ];then
	distribID=$(source /etc/os-release;echo $ID)
	majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

	if   echo $distribID | egrep "centos|rhel|fedora" -q;then
		isRedHatLike=true
	elif echo $distribID | egrep "debian|ubuntu" -q;then
		isDebianLike=true
		if echo $distribID | egrep "ubuntu" -q;then
			isUbuntuLike=true
		fi
	fi

	if [ $isUbuntuLike ];then
		$sudo add-apt-repository -y -u "https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable"
		$sudo apt install -V -y docker-ce
	fi
elif [ $osFamily == Darwin ];then # https://stackoverflow.com/q/78839954/5649639
	brew=$(type -P brew)
	for formula in macfuse docker docker-buildx darwin-containers/formula/containerd darwin-containers/formula/dockerd;do
		$brew info $formula | grep Installed -q || $brew install $formula
	done
	$sudo $brew services list | grep containerd -q || $sudo $brew services start darwin-containers/formula/containerd
	$sudo $brew services list | grep dockerd -q    || $sudo $brew services start darwin-containers/formula/dockerd
fi
