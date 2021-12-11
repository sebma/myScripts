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

function installMinicondaFromScript {
	[ $debug = 1 ] && set -x
	local osFamily=$(uname -s)
	local archi=$(uname -m | \sed "s/^i6/x/")
	local wgetOptions="-c --progress=bar"
	local wget="$(which wget2 2>/dev/null || which wget) $wgetOptions"

	case $osFamily in

	Darwin)	minicondaInstallerScript=Miniconda$Version-latest-MacOSX-x86_64.sh
	;;
	Linux) archi=$(uname -m | \sed "s/^i6/x/"); minicondaInstallerScript=Miniconda$Version-latest-$osFamily-$archi.sh
	;;
	*) ;;
	esac

#	sudo mkdir -v /usr/local/miniconda$Version
#	sudo chown -v $USER:$(id -gn) /usr/local/miniconda$Version

	condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript

	if [ ! -f $minicondaInstallerScript ]
	then
		echo "=> Downloading $condaInstallerURL ..." && $wget $condaInstallerURL
		chmod +x $minicondaInstallerScript
	fi

	if groups | \egrep -wq "sudo|adm|root"
	then
		sudo ./$minicondaInstallerScript -p /usr/local/miniconda$Version -b
	else
		./$minicondaInstallerScript -b
	fi
	test $? = 0 && rm -vf $minicondaInstallerScript
}

function installMinicondaFromRepositories {
	[ $debug = 1 ] && set -x
	local distribType=$(grep ID_LIKE /etc/os-release | cut -d= -f2 | cut -d'"' -f2 | cut -d" " -f1)
	local distribName=$(grep -w ID /etc/os-release | cut -d= -f2 | cut -d'"' -f2 | cut -d" " -f1)
	case $distribType in
	debian)
		\curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
		test -s /etc/apt/trusted.gpg.d/conda.gpg || sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
		rm conda.gpg
		test -s /etc/apt/sources.list.d/conda.list || echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
		apt-cache show conda >/dev/null 2>&1 || sudo apt-get update
		apt-cache show conda >/dev/null || { echo;echo "=> ERROR : Cannot find the conda $distribName package in the <https://repo.anaconda.com/pkgs/misc/debrepo/conda> repository for the $archi architecture.">&2;exit 2; }
		dpkg -l conda >/dev/null 2>&1 || sudo apt install -V conda
		test -s /opt/conda/etc/profile.d/conda.sh && source /opt/conda/etc/profile.d/conda.sh
		conda -V
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
		rpm -q conda >/dev/null 2>&1 || sudo yum install conda
		test -s /opt/conda/etc/profile.d/conda.sh && source /opt/conda/etc/profile.d/conda.sh
		conda -V
	;;
	*) installMinicondaFromScript
	;;
	esac
}

function installMinicondaFromBrew {
	[ $debug = 1 ] && set -x
	local brew="command brew"
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
}

function installMiniconda {
	[ $debug = 1 ] && set -x
	local Version=$1
	local condaInstallerURL=""
	local osFamily=$(uname -s)
	local archi=$(uname -m | \sed "s/^i6/x/")

	if type -P -a conda | grep -q miniconda$Version/bin/conda && [ $reInstall = 0 ]
	then
		echo "=> INFO: Miniconda version $Version is already installed." >&2
		exit 1
	else
		if [ $osFamily = Linux  ]
		then
			case $archi in
			x86) installMinicondaFromScript ;;
			x86_64) installMinicondaFromRepositories ;;
			*) echo "=> ERROR : The $archi architecture is not supported yet.">&2; exit 3 ;;
			esac
		elif [ $osFamily = Darwin ]
		then
			installMinicondaFromBrew
		fi

		test $? = 0 || exit
	#	sudo chown -R $USER:$(id -gn) /usr/local/miniconda$Version
	fi

	if ! which -a conda >/dev/null
	then
	       	echo "=> conda$Version est pas dans le PATH, modifier le fichier ~/.bashrc, fermer le terminal et relancer <$0>." >&2
		exit 1
	else
		test $(uname) = Linux && groups | \egrep -wq "sudo|adm|admin|root|wheel" && symlinkCommand="sudo ln -vsf" || symlinkCommand="ln -vsf"
		local condaVersionPath="$(type -P -a conda | grep miniconda$Version)"
		local condaRelativeDirName=../../miniconda$Version/bin

		cd $(dirname $condaVersionPath)
		for cmd in conda conda-env activate deactivate
		do
			test ! -L $cmd$Version && echo "=> Creating symlink $cmd in $PWD ..." && $symlinkCommand $condaRelativeDirName/$cmd $cmd$Version
		done
	fi
}

function installCondaPythonPackages {
	local minicondaVersion=$1
	local conda="command conda$minicondaVersion"
	local requiredPythonPackageList="$2"
	local envName="$3"
	local osFamily=$(uname -s)

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
set +x

#requiredPythonPackageList="python=$minicondaVersion scipy pandas ipython termcolor"
#installCondaPythonPackages $minicondaVersion "$requiredPythonPackageList" "$envName"

trap - INT
