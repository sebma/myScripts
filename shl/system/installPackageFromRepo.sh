#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

distribID=$(source /etc/os-release;echo $ID)
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
	if [ $# != 2 ];then
		echo "= Usage: $scriptBaseName <user>/<ppa-name> packageList"
		exit 1
	else
		ppa=$1
		shift
		packageList="$@"
		firstPackage=${packageList[0]}
		$sudo add-apt-repository ppa:$ppa
		apt-cache policy $firstPackage | grep $ppa -q || sudo apt update
		$sudo apt install -V ${packageList[@]}
	fi
fi
