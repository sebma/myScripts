#!/usr/bin/env bash

distrib=$(source /etc/os-release;echo $ID)
if [ $distrib != ubuntu ];then
	echo "=> ERROR : This script is for Ubuntu only" >&2
	exit 1
fi

version=$(source /etc/os-release;echo $VERSION_ID)
major=$(cut -d. -f1 <<< $version)
if [ $major -le 14 ];then
	dpkg -l | grep linux-generic-lts-xenial -q || sudo apt install -V linux-generic-lts-xenial
else
	dpkg -l | grep linux-generic-hwe-$version -q || sudo apt install -V linux-generic-hwe-$version
fi
