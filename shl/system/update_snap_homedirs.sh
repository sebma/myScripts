#!/usr/bin/env bash

scriptBaseName=${0/*\//}
if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

# getent passwd sebastien.mansfeld@$domain
if sudo grep "_homedir.*/home/%d" /etc/sssd/sssd.conf -q && ! sudo snap get system homedirs | grep /home/$domain;then
	sudo snap set system homedirs=/home/$domain
	sudo snap get system homedirs
fi
