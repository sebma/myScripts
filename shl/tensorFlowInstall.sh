#!/usr/bin/env bash

set -o errexit
set -o nounset

if [ $(uname -s) = Linux ]
then
	distrib="$(\lsb_release -si)"
	distribCodeName="$(\lsb_release -sc)"
	case $distrib in
		Ubuntu)
			repoBaseURL=http://fr.archive.ubuntu.com/ubuntu/
			grep -q "$distribCodeName " /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName main restricted universe multiverse"
			grep -q "$distribCodeName-security" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName-security main restricted universe multiverse"
			grep -q "$distribCodeName-updates" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName-updates main restricted universe multiverse"
			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xubuntu-desktop"
			test $# -ge 1 && $cudaPackageName=$1 || cudaPackageName=cuda-repo-ubuntu1704_9.1.85-1_amd64.deb
			wget -N http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/$cudaPackageName
		;;
		Debian)
			repoBaseURL=http://ftp.fr.debian.org/debian/
			grep -q "$distribCodeName " /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName main contrib non-free"
			grep -q "$distribCodeName/updates" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName/updates main contrib non-free"
			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xfce4"
		;;
		*) ;;
	esac
elif [ $(uname -s) = Darwin ]
then
	echo "=> TO DO."
fi

case $distrib in 
	Ubuntu)
		installCommand="sudo apt install -V"
		consoleTools="lsb-release bash-completion vim command-not-found gpm dfc git smartmontools inxi aria2 gdebi-core"
		updateRepo="sudo apt update"
		$updateRepo
		$installCommand $consoleTools $graphicTools
		dpkg -l | awk '/^ii/{print$2}' | grep -Pq "nvidia-\d+$" || $installCommand nvidia-384
		sudo gdebi -n $cudaPackageName
		keyIDsList="$(LANG=C $updateRepo 2>&1 | awk '/NO_PUBKEY/{print $NF}' | sort -u | tr '\n' ' ')"
		test -n "$keyIDsList" && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $keyIDsList
		$updateRepo
		$installCommand cuda
		rm -v $cudaPackageName
	;;
	*);;
esac
