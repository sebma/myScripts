#!/usr/bin/env bash

set -o nounset

trap 'rc=130;set +x;echo "=> $BASH_SOURCE: CTRL+C Interruption trapped.">&2;exit $rc' INT

scriptBaseName=$(basename $0)
debug=0
reInstall=0

function scriptHelp {
	cat <<-EOF >&2
	=> Usage:
	$scriptBaseName -h : this help
	$scriptBaseName -2 : install miniconda2
	$scriptBaseName -3 : install miniconda3
	$scriptBaseName -n Name : install miniconda and C.P.A. DEV Python requirements in "Name" environment
EOF
	exit -1
}

function installMiniconda {
	local Version=$1
	local condaInstallerURL=""
	local systemType=$(uname -s)
	local wgetOptions="-c --progress=bar"
	local wget="$(which wget) $wgetOptions"
	local wget2="$(which wget2) $wgetOptions"

	[ $debug = 1 ] && set -x
#	if which -a conda | grep -q miniconda$Version/bin/conda
	if which -a conda | grep -q miniconda$Version/bin/conda && [ $reInstall = 0 ]
	then
		echo "=> INFO: Miniconda version $Version is already installed." >&2
		exit 1
	else
		case $systemType in
		Darwin)	minicondaInstallerScript=Miniconda$Version-latest-MacOSX-x86_64.sh
		;;
		Linux) archi=$(uname -m | \sed "s/^i6/x/"); minicondaInstallerScript=Miniconda$Version-latest-$systemType-$archi.sh
		;;
		*) ;;
		esac

	#	sudo mkdir -v /usr/local/miniconda$Version
	#	sudo chown -v $USER:$(id -gn) /usr/local/miniconda$Version

		condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
		if [ $systemType = Linux  ] 
		then 
			local distribType=$(grep ID_LIKE /etc/os-release | cut -d= -f2 | cut -d'"' -f2 | cut -d" " -f1)
			case $distribType in
			debian)
				\curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
				test -s /etc/apt/trusted.gpg.d/conda.gpg || sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
				rm conda.gpg
				test -s /etc/apt/sources.list.d/conda.list || echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
				apt show conda >/dev/null 2>&1 || sudo apt-get update
				sudo apt install -V conda
			;;
			rhel|fedora|centos)
				rpm --import https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc
				cat <<-EOF | sudo tee /etc/yum.repos.d/conda.repo
[conda]

name=Conda

baseurl=https://repo.anaconda.com/pkgs/misc/rpmrepo/conda

enabled=1

gpgcheck=1

gpgkey=https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc

EOF
				sudo yum install conda
			;;
			*)
				if [ ! -f $minicondaInstallerScript ]
				then
					echo "=> Downloading $condaInstallerURL ..." && $wget2 $condaInstallerURL || $wget $condaInstallerURL
					chmod +x $minicondaInstallerScript
				fi

				if groups | \egrep -wq "sudo|adm|root" 
				then
					sudo ./$minicondaInstallerScript -p /usr/local/miniconda$Version -b 
				else
					./$minicondaInstallerScript -b
				fi
				test $? = 0 && rm -vf $minicondaInstallerScript
			;;
			esac
		elif [ $systemType = Darwin ] 
		then
			brew=$(which brew)
			$brew -v || {
				echo "=> ERROR : Homebrew is not installed, you must install it first." >&2
				exit -1
			}

			$brew update
			if [ $Version = 2 ] 
			then
				$brew tap caskroom/versions
				$brew cask install miniconda2
				$(which conda) install argcomplete # Add: eval "$(register-python-argcomplete conda)" to your .profile
			else
				$brew tap caskroom/cask
				$brew cask install miniconda
			fi
		fi

		test $? = 0 || exit
	#	sudo chown -R $USER:$(id -gn) /usr/local/miniconda$Version
	fi

	if ! which -a conda >/dev/null
	then
	       	echo "=> conda$Version est pas dans le PATH, modifier le fichier ~/.bashrc, fermer le terminal et relancer <$0>." >&2
		exit 1
	else
		test $(uname) = Linux && groups | \egrep -wq "sudo|adm|admin|root" && symlinkCommand="sudo ln -vsf" || symlinkCommand="ln -vsf"
		local condaVersionPath=$(which -a conda | grep miniconda$Version)
		local condaRelativeDirName=../../miniconda$Version/bin

		cd $(dirname $condaVersionPath)
		for cmd in conda conda-env activate deactivate
		do
			test ! -L $cmd$Version && echo "=> Creating symlink $cmd in $PWD ..." && $symlinkCommand $condaRelativeDirName/$cmd $cmd$Version 
		done
	fi
	set +x
}

function installCondaPythonPackages {
	local minicondaVersion=$1
	local conda=$(which conda$minicondaVersion)
	local requiredPythonPackageList="$2"
	local envName="$3"
	local systemType=$(uname -s)

	if test -n $envName
	then
		$conda create  -n "$envName" $requiredPythonPackageList
		$conda install -n "$envName" -c conda-forge ipdb
		echo "=> INFO: Do not forget to type : " >&2
		echo "source activate $envName" >&2
	else
		echo "=> $conda install $requiredPythonPackageList ..."
		$conda install $requiredPythonPackageList
		$conda install -c conda-forge ipdb
	fi
}

function runScriptWithArgs {
	local OPTSTRING=23hrxn:

	while getopts $OPTSTRING NAME; do
		case "$NAME" in
		2|3) minicondaVersion=$NAME ;;
		n) envName="$OPTARG" ;;
		r) reInstall=1;;
		x) debug=1;;
		h|*) scriptHelp ;;
		esac
	done
	[ $OPTIND = 1 ] && scriptHelp
	shift $((OPTIND-1)) #non-option arguments
}

runScriptWithArgs $@
installMiniconda $minicondaVersion

#requiredPythonPackageList="python=$minicondaVersion scipy pandas ipython termcolor"
#installCondaPythonPackages $minicondaVersion "$requiredPythonPackageList" "$envName"

trap - INT
