#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
PRETTY_NAME=""
PRETTY_NAME=$(source /etc/os-release;echo $PRETTY_NAME)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	sudo=""
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=$(type -P sudo)
	isDebianLike=true
fi

test $(id -u) == 0 && sudo=""
scriptBaseName=${0/*\//}

if $isDebianLike;then
	if [ $# -lt 2 ];then
		echo "= Usage: $scriptBaseName ppa:<user>/<ppa-name>|repo_url packageList"
		exit 1
	else
		repoLine=$1
		if ! [[ $1 =~ ^"deb " ]];then
			ppa=${1}
			ppaWithoutPrefix=${1/ppa:}
			shift
			yes | $sudo add-apt-repository $ppa
		else
			echo $repoLine | $sudo tee /etc/apt/sources.list.d/$2.list
			shift
		fi

		packageList=( $@ )
		firstPackage="${packageList[0]}"

		if ! [[ $repoLine =~ ^"deb " ]];then
			apt-cache policy $firstPackage | grep $ppaWithoutPrefix -q || $sudo apt update
			echo
			if apt-cache policy $firstPackage | grep $ppaWithoutPrefix -q;then
				$sudo apt install -V ${packageList[@]}
			else
				echo "=> No $firstPackage for $PRETTY_NAME, removing $ppa repository ..."
				echo
				yes | $sudo add-apt-repository $ppa -r
			fi
		else
			apt-cache policy $firstPackage | egrep https?:// -q || $sudo apt update
			echo
			if apt-cache policy $firstPackage | egrep https?:// -q;then
				 $sudo apt install -V ${packageList[@]}
			else
				echo "=> No $firstPackage for $PRETTY_NAME, removing repository ..."
				echo
				$sudo rm /etc/apt/sources.list.d/$firstPackage.list
				$sudo apt update
			fi
		fi
		echo "=> Done."
	fi
fi
