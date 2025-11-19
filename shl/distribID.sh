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
	case $ID_LIKE in
		rhel|centos|fedora) isRedHatLike=true;;
		debian) isDebianLike=true;;
	esac
	distribID=$ID_LIKE
else
	ID=$(source /etc/os-release;echo $ID)
	case $ID in
		debian) isDebianLike=true;;
		alpine) isAlpineLike=true;;
		arch)   isArchLike=true;;
		photon) isPhotonLike=true;;
		*) ;;
	esac
	distribID=$ID
fi

echo $distribID
