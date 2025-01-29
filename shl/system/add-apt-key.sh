#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# = 0 ];then
	echo "=> Usage $scriptBaseName fingerPrint" >&2
	exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

declare -x {isDebian,isRedHat,isAlpine}Like=false
distribID=$(source /etc/os-release;echo $ID)
if   echo $distribID | egrep "centos|rhel|fedora" -q;then
	isRedHatLike=true
elif echo $distribID | egrep "debian|ubuntu" -q;then
	isDebianLike=true
elif echo $distribID | egrep "alpine" -q;then
	isAlpineLike=true
fi

for fingerPrint
do
	$sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $fingerPrint
done
