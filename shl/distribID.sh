#!/usr/bin/env bash

set -eu
scriptBaseName=${0/*\//}
scriptDirName=${0%/*}

if [ $# != 0 ];then
	echo "=> Usage $scriptBaseName" >&2
	exit 1
fi
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

declare -x {isDebian,isRedHat,isAlpine}Like=false

ID_LIKE=""
ID_LIKE=$(source /etc/os-release;echo $ID_LIKE)
if [ -n "$ID_LIKE" ];then
	if   echo $ID_LIKE | egrep "rhel|centos|fedora" -q;then
		isRedHatLike=true
	elif echo $ID_LIKE| egrep "debian|ubuntu" -q;then
		isDebianLike=true
	elif echo $ID_LIKE| egrep "alpine" -q;then
		isAlpineLike=true
	fi
	distribID=$ID_LIKE
else
	ID=$(source /etc/os-release;echo $ID)
	if   echo $ID_LIKE | egrep "rhel|centos|fedora" -q;then
		isRedHatLike=true
	elif echo $ID_LIKE| egrep "debian|ubuntu" -q;then
		isDebianLike=true
	elif echo $ID_LIKE| egrep "alpine" -q;then
		isAlpineLike=true
	fi
	distribID=$ID
fi

echo $distribID
