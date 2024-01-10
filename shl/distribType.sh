#!/usr/bin/env bash

distribName () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if type -P lsb_release >/dev/null 2>&1; then
			osName=$(lsb_release -si | awk '{print tolower($0)}')
			[ $osName = "n/a" ] && osName=$(source /etc/os-release && echo $ID)
		elif [ -s /etc/os-release ]; then
			osName=$(source /etc/os-release && echo $ID)
		fi
	elif [ $osFamily = Darwin ]; then
		osName="$(sw_vers -productName)"
	elif [ $osFamily = Android ]; then
		osName=Android
	elif [ $osFamily = VMkernel ]; then # ESXi
		osName=ESXi
  	else
		osName=$OSTYPE
	fi

	echo $osName | awk '{print tolower($0)}'
}

distribType () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	distribName=$(distribName)

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
	elif [ $osFamily = VMkernel ]; then # ESXi
		distribType=ESXi
 	else
		type -P bash >/dev/null 2>&1 && distribType=$(bash -c 'echo $OSTYPE') || distribType=$osFamily
	fi

	echo $distribType
}

distribType
