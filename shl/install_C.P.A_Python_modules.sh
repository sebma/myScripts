#!/usr/bin/env bash

set -o nounset

envName=""
scriptBaseName=$(basename $0)
function scriptHelp {
	cat <<-EOF >&2
	=> Usage:
	$scriptBaseName -h : this help
	$scriptBaseName -n Name : install miniconda and C.P.A. DEV Python requirements in "Name" environment
	$scriptBaseName -2 : install miniconda2
	$scriptBaseName -3 : install miniconda3
EOF
	exit 1
}

function installMiniconda {
	local Version=$1
	local condaInstallerURL=""
	if type -P -a conda | grep -q miniconda$Version/bin/conda
	then
		echo "=> INFO: Miniconda version $Version is already installed." >&2
	else
		case $(uname -s) in
		Darwin)	condaInstallerURL=https://repo.continuum.io/miniconda/Miniconda$Version-latest-MacOSX-x86_64.sh
			;;
		Linux) [ $(uname -m) = i686 ] && archi=x86 || archi=$(uname -m)
				condaInstallerURL=https://repo.continuum.io/miniconda/Miniconda$Version-latest-$(uname -s)-$archi.sh
			;;
		*) ;;
		esac

	#	sudo mkdir -v /usr/local/miniconda$Version
	#	sudo chown -v $USER:$(id -gn) /usr/local/miniconda$Version
		installerScript=$(basename $condaInstallerURL)
		test -f $installerScript || curl -#O $condaInstallerURL
		chmod +x $installerScript

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
			groups | \egrep -wq "sudo|adm|root" && sudo ./$installerScript || ./$installerScript
		fi

		test $? = 0 && rm -v $installerScript || exit
	#	sudo chown -R $USER:$(id -gn) /usr/local/miniconda$Version
	fi

	if ! which conda$Version >/dev/null #Si le lien symbolique, par exemple: conda2 n'est pas dans le PATH
	then
		local condaVersionPath=$(which -a conda | grep miniconda$Version)
		cd $(dirname $condaVersionPath)
		local condaRelativeDirName=../../miniconda$Version/bin
		ln -vsf $condaRelativeDirName/conda conda$Version && ln -vsf $condaRelativeDirName/conda-env conda-env$Version && ln -vsf $condaRelativeDirName/activate activate$Version && ln -vsf $condaRelativeDirName/deactivate deactivate$Version
	fi
}

function installCondaPythonPackages {
	local minicondaVersion=$1
	local conda=$(which conda$minicondaVersion)
	local CPARequiredPythonPackageList="$2"
	local envName="$3"

	if test -n "$envName" && ! $conda env list | grep -wq "$envName"
	then
		set -x
		$conda create  -n "$envName" $CPARequiredPythonPackageList
		$conda install -n "$envName" -c conda-forge ipdb
		set +x
		echo "=> INFO: Do not forget to type : " >&2
		echo "source activate $envName" >&2
	else
		set -x
		$conda install $CPARequiredPythonPackageList
		$conda install -c conda-forge ipdb
		set +x
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

function main {
	runScriptWithArgs $@
	installMiniconda $minicondaVersion

	CPARequiredPythonPackageList="python=$minicondaVersion matplotlib scipy pandas ipython termcolor"
	installCondaPythonPackages $minicondaVersion "$CPARequiredPythonPackageList" "$envName"
}

main $@
