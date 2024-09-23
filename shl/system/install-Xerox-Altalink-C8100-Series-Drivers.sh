#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 2 ];then
	echo "=> Usage: $scriptBaseName variablesDefinitionFile version" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit
version=$2

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

if $isDebianLike;then
	wget -c -nc https://download.support.xerox.com/pub/drivers/CQ8580/drivers/linux/pt_BR/XeroxOfficev5Pkg-Linuxx86_64-5.20.661.4684.deb
	sudo apt install -V ./XeroxOfficev5Pkg-Linuxx86_64-5.20.661.4684.deb
elif $isRedHatLike;then
	wget -c -nc https://download.support.xerox.com/pub/drivers/CQ8580/drivers/linux/pt_BR/XeroxOfficev5Pkg-Linuxx86_64-5.20.661.4684.rpm
	sudo yum install ./XeroxOfficev5Pkg-Linuxx86_64-5.20.661.4684.rpm
fi
