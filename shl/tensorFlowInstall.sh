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
			updateRepo="sudo apt update"
			$updateRepo

			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xubuntu-desktop"
			test $# -ge 1 && $cudaPackageFileName=$1 || cudaPackageFileName=cuda-repo-ubuntu1704_9.1.85-1_amd64.deb
			wget -N http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/$cudaPackageFileName
		;;
		Debian)
			repoBaseURL=http://ftp.fr.debian.org/debian/
			grep -q "$distribCodeName " /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName main contrib non-free"
			grep -q "$distribCodeName/updates" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName/updates main contrib non-free"
			updateRepo="sudo apt update"
			$updateRepo

			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xfce4"
		;;
		*) ;;
	esac
elif [ $(uname -s) = Darwin ]
then
	echo "=> TO DO."
fi

cudaVersion=9-0
case $distrib in 
	Ubuntu)
		installCommand="sudo apt install -V"
		consoleTools="lsb-release bash-completion vim python-argcomplete command-not-found gpm dfc git smartmontools inxi aria2 gdebi-core speedtest-cli"
		$installCommand $consoleTools $graphicTools
		if ! dpkg -l "cuda-repo-ubuntu*" | grep -q "^ii.*cuda-repo-ubuntu" #Si le depot cuda n'est pas configure
		then
			sudo gdebi -n $cudaPackageFileName
			keyIDsList="$(LANG=C $updateRepo 2>&1 | awk '/NO_PUBKEY/{print $NF}' | sort -u | tr '\n' ' ')"
			test -n "$keyIDsList" && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $keyIDsList
			$updateRepo
		fi
		test -s /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-$distribCodeName.list || { sudo add-apt-repository ppa:graphics-drivers/ppa -y;$updateRepo; }
#		dpkg -l | awk '/^ii/{print$2}' | grep -Pq "nvidia-\d+$" || $installCommand nvidia-384
		$installCommand cuda-$cudaVersion nvidia-390 libcupti-dev
	;;
	*);;
esac

cudaVersion=$(echo $cudaVersion | tr '-' '.')
cuDNN_ArchiveFile=cudnn-$cudaVersion-linux-x64-v7.1.tgz
wget -N https://s3.amazonaws.com/open-source-william-falcon/$cuDNN_ArchiveFile
tar -xzvf $cuDNN_ArchiveFile
sudo cp -pv cuda/include/cudnn.h /usr/local/cuda/include
sudo cp -pv cuda/lib64/libcudnn* /usr/local/cuda/lib64
sudo chmod -v a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*

conda install argcomplete
tensorFlowEnvName=tensorFlow
conda env list | grep -q $tensorFlowEnvName || conda create -n $tensorFlowEnvName
conda install -n $tensorFlowEnvName python=3 tensorflow scikit-learn keras
conda install -n $tensorFlowEnvName ipython argcomplete
conda install -n $tensorFlowEnvName -c aaronzs tensorflow-gpu

rm -vi $cudaPackageFileName $cuDNN_ArchiveFile
