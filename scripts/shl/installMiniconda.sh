#!/usr/bin/env bash

set -o nounset

scriptBaseName=$(basename $0)
function scriptHelp {
	cat <<-EOF >&2
	=> Usage:
	$scriptBaseName -h : this help
	$scriptBaseName -2 : install miniconda2
	$scriptBaseName -3 : install miniconda3
	$scriptBaseName -n Name : install miniconda and C.P.A. DEV Python requirements in "Name" environment
EOF
	exit 1
}

function installMiniconda {
	local Version=$1
	local condaInstallerURL=""
	if which -a conda | grep -q miniconda$Version/bin/conda
	then
		echo "=> INFO: Miniconda version $Version is already installed." >&2
	else
		case $(uname -s) in
		Darwin)	minicondaInstallerScript=Miniconda$Version-latest-MacOSX-x86_64.sh
		;;
		Linux) [ $(uname -m) = i686 ] && archi=x86 || archi=$(uname -m)
			minicondaInstallerScript=Miniconda$Version-latest-$(uname -s)-$archi.sh
		;;
		*) ;;
		esac

	#	sudo mkdir -v /usr/local/miniconda$Version
	#	sudo chown -v $USER:$(id -gn) /usr/local/miniconda$Version

		condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
		test ! -f $minicondaInstallerScript && echo "=> Downloading $condaInstallerURL ..." && curl -#O $condaInstallerURL
		chmod +x $minicondaInstallerScript

		brew=$(which brew)
		if [ $(uname -s) = Darwin ] 
		then
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
		elif [ $(uname -s) = Linux  ] 
		then 
			groups | \egrep -wq "sudo|adm|root" && sudo ./$minicondaInstallerScript -p /usr/local/miniconda$Version -b || ./$minicondaInstallerScript -b
		fi
		

		test $? = 0 && rm -v $minicondaInstallerScript || exit
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
	local OPTSTRING=23hn:

	while getopts $OPTSTRING NAME; do
		case "$NAME" in
		2|3) minicondaVersion=$NAME ;;
		n) envName="$OPTARG" ;;
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
