#!/usr/bin/env bash

function main {
	set -o errexit
	set -o nounset
	
	local os=$(uname -s)
	local -r isAdmin=$(groups | egrep -wq "sudo|adm|admin|root" && echo true || echo false)
	
	if [ $os = Linux ]
	then
		if [ $(uname -m) != x86_64 ]
		then
			echo "=> ERROR: You must use a 64 bits Linux." >&2
			exit 1
		fi
	
		shellInitFileName=~/.$(basename $SHELL)rc
		if $isAdmin
		then
			sudo=sudo
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
		
					graphicTools="gsmartcontrol gparted lshw-gtk numlockx smart-notifier xfce4 xfce4-mount-plugin xubuntu-desktop"
					installCommand="sudo apt install -V"
			
					echo
					echo "=> Installing $(lsb_release -sd) console tools ..."
					echo
					consoleTools="lsb-release bash-completion vim python-argcomplete command-not-found gpm conky-all dfc git smartmontools inxi aria2 gdebi-core speedtest-cli"
					$installCommand $consoleTools
			
					echo
					echo "=> Installing NVIDIA drivers and the lightwight Xfce environment ..."
					if test -f /proc/driver/nvidia/version
					then
						echo "==> INFO : The NVIDIA drivers are already installed :"
						echo
						cat /proc/driver/nvidia/version
						echo
						$installCommand $graphicTools
					else
						echo
						if ! test -s /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-$distribCodeName.list 
						then
							sudo add-apt-repository ppa:graphics-drivers/ppa -y
							$updateRepo
						fi
	
						nVidiaDriversVersion=390
						$installCommand nvidia-$nVidiaDriversVersion $graphicTools
					fi
			
					echo
					echo "=> Installing CUDA ..."
					if which nvcc >/dev/null 2>&1
					then
						echo "==> INFO : cuda is already installed :"
						echo
						nvcc -V
					else
						echo
						cudaPackageName=cuda-9-0
						cudaRepoURL=http://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -sr | cut -d. -f1)04/$(uname -m)
	
						if ! grep $cudaRepoURL /etc/apt/sources.list /etc/apt/sources.list.d/*
						then
							echo deb $cudaRepoURL / | sudo tee /etc/apt/sources.list.d/cuda.list
							keyIDsList="$(LANG=C $updateRepo 2>&1 | awk '/NO_PUBKEY/{print $NF}' | sort -u | tr '\n' ' ')"
							test -n "$keyIDsList" && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $keyIDsList
							$updateRepo
						fi
	
						$installCommand $cudaPackageName
					fi
	
					CUDA_HOME=$(dirname $(dirname $(which nvcc)))
					dpkg -l | grep -q "^ii.*libcupti-dev" || $installCommand libcupti-dev
					conda list | grep -q argcomplete || conda install argcomplete
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
		
			
			echo
			echo "=> Installing cuDNN for cuda ..."
			if grep -q CUDNN_MAJOR $CUDA_HOME/include/cudnn.h
			then
				printf "==> INFO: cuDNN is already installed and the version is : %s\n" $(grep -v CUDNN_VERSION $CUDA_HOME/include/cudnn.h | awk '/CUDNN_MAJOR|CUDNN_MINOR|CUDNN_PATCHLEVEL/{printf$NF"."}')
			else
				echo
				cudaVersion=$(echo $cudaPackageName | cut -d- -f2- | tr "-" .)
				cuDNN_ArchiveFileBaseName=cudnn-$cudaVersion-linux-x64-v7.1.tgz
				wget -P /tmp -N https://s3.amazonaws.com/open-source-william-falcon/$cuDNN_ArchiveFileBaseName
				sync
				du -h /tmp/$cuDNN_ArchiveFileBaseName
				tar -xzvf /tmp/$cuDNN_ArchiveFileBaseName
				sudo cp -pv cuda/include/cudnn.h $CUDA_HOME/include
				sudo cp -pv cuda/lib64/libcudnn* $CUDA_HOME/lib64
				sync
				sudo chmod -v a+r $CUDA_HOME/include/cudnn.h $CUDA_HOME/lib64/libcudnn*
				rm -fr cuda
#				rm -v /tmp/$cuDNN_ArchiveFileBaseName
			fi
		else
			echo "=> INFO: You are not an administrator "
			sudo=""
		fi

		if test -n "$CUDA_HOME" 
		then
			echo export CUDA_HOME=$CUDA_HOME >> $shellInitFileName
			echo $PATH | grep -q $CUDA_HOME || echo 'export PATH=$CUDA_HOME/bin${PATH:+:${PATH}}' >> $shellInitFileName
			echo $LD_LIBRARY_PATH | grep -q $CUDA_HOME || echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64"' >> $shellInitFileName
		fi
	
	elif [ $os = Darwin ]
	then
		echo "=> TO DO."
	fi
	
	if [ $os = Linux ] || [ $os = Darwin ]
	then
		echo
		echo "=> Installing Miniconda3 ..."
		echo
		if $isAdmin
		then
			CONDA_HOME=/usr/local/miniconda3
			CONDA_ENVS=$CONDA_HOME/envs
		else
			CONDA_HOME=$HOME/miniconda3
			CONDA_ENVS=$HOME/.conda/envs
		fi

		if ! which conda
		then
			if [ $(uname -m) = x86_64 ]
			then
				test $os = Linux && minicondaInstallerScript=Miniconda3-latest-Linux-x86_64.sh || minicondaInstallerScript=Miniconda3-latest-MacOS-x86_64.sh
				condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
				curl -#O $condaInstallerURL
				chmod -v +x $minicondaInstallerScript
				$sudo ./$minicondaInstallerScript -p $CONDA_HOME -b
				test $? = 0 && rm -vi $minicondaInstallerScript
			fi
		fi

		echo $PATH | grep -q $CONDA_HOME || echo 'export PATH=$CONDA_HOME/bin${PATH:+:${PATH}}' >> $shellInitFileName

		echo
		echo "=> Installing tensorflow-gpu conda environment ..."
		echo
		tensorFlowEnvName=tensorFlow
		conda env list | grep -q $tensorFlowEnvName || $sudo $(which conda) create -p $CONDA_ENVS/$tensorFlowEnvName
		$sudo $(which conda) install -n $tensorFlowEnvName python=3 scikit-learn keras
		$sudo $(which conda) install -n $tensorFlowEnvName ipython argcomplete
		$sudo $(which conda) install -n $tensorFlowEnvName -c aaronzs tensorflow tensorflow-gpu
		conda list -n $tensorFlowEnvName | egrep -w "packages in environment|keras|python|scikit-learn|tensorflow"
	fi
}

main $@
