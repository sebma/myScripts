#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
PRETTY_NAME=$(source /etc/os-release;echo $PRETTY_NAME)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	sudo=""
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	sudo=sudo
	isDebianLike=true
fi

test $(id -u) == 0 && sudo=""
scriptBaseName=${0/*\//}

if $isDebianLike;then
	if [ $# -lt 2 ];then
		echo "= Usage: $scriptBaseName ppa:<user>/<ppa-name>|repo_url packageList"
		exit 1
	else
		ppa=${1}
		ppaWithoutPrefix=${1/ppa:}
		shift
		packageList=( $@ )
		firstPackage="${packageList[0]}"
		yes | $sudo add-apt-repository $ppa
		apt-cache policy $firstPackage | grep $ppaWithoutPrefix -q || $sudo apt update
		if apt-cache policy $firstPackage | grep $ppaWithoutPrefix -q;then
			$sudo apt install -V ${packageList[@]}
		else
			echo "=> No $firstPackage for $PRETTY_NAME, removing $ppa repository ..."
			yes | $sudo add-apt-repository $ppa -r
		fi
		echo "=> Done."
	fi
fi
