#!/usr/bin/env bash

if [ $# != 1 ];then
	echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
	exit 1
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

sudo add-apt-repository ppa:ubuntu-enterprise-desktop/adsys
sudo apt install -V adsys
