#!/usr/bin/env bash

distribName () {
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if which lsb_release >/dev/null 2>&1; then
			osName=$(lsb_release -si)
			[ $osName = "n/a" ] && osName=$(\sed -n "s/[\"']//g;s/^ID=//p;" /etc/os-release)
		elif [ -s /etc/os-release ]; then
			osName=$(\sed -n "s/[\"']//g;s/^ID=//p;" /etc/os-release)
		fi
	elif [ $osFamily = Darwin ]; then
		osName="$(sw_vers -productName)"
	elif [ $osFamily = Android ]; then
		osName=Android
	else
		osName=$OSTYPE
	fi

	echo $osName | awk '{print tolower($0)}'
}

distribType () {
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
	else
		which bash >/dev/null 2>&1 && distribType=$(bash -c 'echo $OSTYPE') || distribType=$osFamily
	fi

	echo $distribType
}

distribType
