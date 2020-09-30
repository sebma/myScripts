#!/usr/bin/env bash

distribType ()
{
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	distribName=$(distribName.sh)

	if [ $osFamily = Linux ]; then
		case $distribName in
			sailfishos|rhel|fedora|centos) distribType=redhat ;;
			ubuntu) distribType=debian;;
			*) distribType=$distribName ;;
		esac
	elif [ $osFamily = Darwin ]; then
			distribType=Darwin
	elif [ $osFamily = Android ]; then
			distribType=Android
	else
		which bash >/dev/null 2>&1 && distribType=$(bash -c 'echo $OSTYPE') || distribType=$osFamily
	fi

	echo $distribType
}

distribType
