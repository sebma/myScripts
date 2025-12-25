#!/usr/bin/env bash

echo $OSTYPE | grep -q android && export osFamily=Android || export osFamily=$(uname -s)
scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> Usage: $scriptBaseName wifiName" >&2
	exit 1
fi

wifiName="$1"
if [ $osFamily == Darwin ];then
	security find-generic-password -ga "$wifiName" 2>&1 | awk -F'"' '/password:/{print$2}'
fi
