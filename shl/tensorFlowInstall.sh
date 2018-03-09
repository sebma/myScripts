#!/usr/bin/env bash

set -o errexit
set -o nounset

if [ $(uname -s) = Linux ]
then
	if [ $(uname -m) != x86_64 ]
	then
		echo "=> ERROR: You must use a 64 bits Linux." >&2
		exit 1
	fi

	shellInitFileName=~/.$(basename $SHELL)rc
	distrib="$(\lsb_release -si)"
	distribCodeName="$(\lsb_release -sc)"
	case $distrib in
		Ubuntu)
			echo "=> Checking and fixing (if necessary) the standard $distrib repositories ..."
			echo
			repoBaseURL=http://fr.archive.ubuntu.com/ubuntu/
			grep -q "$distribCodeName " /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName main restricted universe multiverse"
			grep -q "$distribCodeName-security" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName-security main restricted universe multiverse"
			grep -q "$distribCodeName-updates" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName-updates main restricted universe multiverse"
			updateRepo="sudo apt update"
			$updateRepo

			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xubuntu-desktop xfce4-mount-plugin"
			installCommand="sudo apt install -V"
	
			echo
			echo "=> Installing $(lsb_release -sd) console tools ..."
			echo
			consoleTools="lsb-release bash-completion vim python-argcomplete command-not-found gpm dfc git smartmontools inxi aria2 gdebi-core speedtest-cli"
			$installCommand $consoleTools
	
			echo
			echo "=> Installing NVIDIA Drivers and the lightwight Xfce environment ..."
			echo
			nVidiaDriversVersion=390
			if ! test -s /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-$distribCodeName.list 
			then
				sudo add-apt-repository ppa:graphics-drivers/ppa -y
				$updateRepo
			fi
			$installCommand nvidia-$nVidiaDriversVersion $graphicTools
	
			echo
			echo "=> Installing CUDA ..."
			echo
			cudaPackageName=cuda-9-0
			cudaRepoURL=http://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -sr | cut -d. -f1)04/$(uname -m)
	#		if ! dpkg -l "cuda-repo-ubuntu*" | grep -q "^ii.*cuda-repo-ubuntu" #Si le depot cuda n'est pas configure
			if ! grep $cudaRepoURL /etc/apt/sources.list /etc/apt/sources.list.d/*
			then
				echo deb $cudaRepoURL / | sudo tee /etc/apt/sources.list.d/cuda.list
				keyIDsList="$(LANG=C $updateRepo 2>&1 | awk '/NO_PUBKEY/{print $NF}' | sort -u | tr '\n' ' ')"
				test -n "$keyIDsList" && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $keyIDsList
				$updateRepo
			fi
	#		dpkg -l | awk '/^ii/{print$2}' | grep -Pq "nvidia-\d+$" || $installCommand nvidia-384
			$installCommand $cudaPackageName
		;;
		Debian)
			echo "=> Checking and fixing (if necessary) the standard $distrib repositories ..."
			echo
			repoBaseURL=http://ftp.fr.debian.org/debian/
			grep -q "$distribCodeName " /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName main contrib non-free"
			grep -q "$distribCodeName/updates" /etc/apt/sources.list || sudo add-apt-repository "deb $repoBaseURL $distribCodeName/updates main contrib non-free"
			updateRepo="sudo apt update"
			$updateRepo

			graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xfce4 xfce4-mount-plugin"
			installCommand="sudo apt install -V"
		;;
		*) ;;
	esac

	
	cudaVersion=$(echo $cudaPackageName | cut -d- -f2- | tr "-" .)
	echo
	echo "=> Installing cuDNN for cuda v$cudaVersion ..."
	echo
	cuDNN_ArchiveFileBaseName=cudnn-$cudaVersion-linux-x64-v7.1.tgz
	wget -P /tmp -N https://s3.amazonaws.com/open-source-william-falcon/$cuDNN_ArchiveFileBaseName
	sync
	du -h /tmp/$cuDNN_ArchiveFileBaseName
	tar -xzvf /tmp/$cuDNN_ArchiveFileBaseName
	sudo cp -pv cuda/include/cudnn.h /usr/local/cuda/include
	sudo cp -pv cuda/lib64/libcudnn* /usr/local/cuda/lib64
	sync
	rm -fr cuda
	sudo chmod -v a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
	
	echo
	echo "=> Installing Miniconda3 ..."
	echo
	if ! which conda
	then
		if [ $(uname -m) = x86_64 ]
		then
			minicondaInstallerScript=Miniconda3-latest-Linux-x86_64.sh
			condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
			curl -#O $condaInstallerURL
			chmod -v +x $minicondaInstallerScript
			if groups | \egrep -wq "sudo|adm|root" 
			then
				CONDA_HOME=/usr/local/miniconda3
				sudo ./$minicondaInstallerScript -p $CONDA_HOME -b
			else
				./$minicondaInstallerScript -b
				CONDA_HOME=$HOME/miniconda3
			fi
			test $? = 0 && rm -vi $minicondaInstallerScript
			echo $PATH | grep -q $CONDA_HOME || echo 'export PATH=$CONDA_HOME/bin${PATH:+:${PATH}}' >> $shellInitFileName
		fi
	fi

	echo
	echo "=> Installing tensorflow-gpu conda environment ..."
	echo
	$installCommand libcupti-dev
	conda install argcomplete
	tensorFlowEnvName=tensorFlow
	conda env list | grep -q $tensorFlowEnvName || conda create -n $tensorFlowEnvName
	conda install -n $tensorFlowEnvName python=3 tensorflow scikit-learn keras
	conda install -n $tensorFlowEnvName ipython argcomplete
	conda install -n $tensorFlowEnvName -c aaronzs tensorflow-gpu
	conda list -n $tensorFlowEnvName | egrep -w "packages in environment|keras|python|scikit-learn|tensorflow|tensorflow-gpu"
	
	CUDA_HOME=/usr/local/cuda
	grep -q CUDA_HOME ~/.$(basename $SHELL)rc || echo export CUDA_HOME=$CUDA_HOME >> $shellInitFileName
	echo $PATH | grep -q $CUDA_HOME || echo 'export PATH=$CUDA_HOME/bin${PATH:+:${PATH}}' >> $shellInitFileName
	echo $LD_LIBRARY_PATH | grep -q $CUDA_HOME || echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64"' >> $shellInitFileName
	rm -vi /tmp/$cuDNN_ArchiveFileBaseName

elif [ $(uname -s) = Darwin ]
then
	echo "=> TO DO."
fi
