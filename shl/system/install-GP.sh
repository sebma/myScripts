#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=sudo
scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName globalProtectVersion" >&2
	exit -1
else
	globalProtectVersion=$1
fi

globalProtectArchive=$(ls ../GlobalProtect/PanGPLinux-$globalProtectVersion-*.tgz)
if [ -n "$globalProtectArchive" ];then
	mkdir $HOME/globalProtect-$globalProtectVersion
	tar -C $HOME/globalProtect-$globalProtectVersion -xf $globalProtectArchive
	cd $HOME/globalProtect-$globalProtectVersion
	$sudo ./gp_install.sh
	retCode=$?
	[ $retCode == 0 ] && rm -fr $HOME/globalProtect-$globalProtectVersion
	dpkg -l | grep globalprotect
fi
