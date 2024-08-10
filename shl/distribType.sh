#!/usr/bin/env bash

distribType () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	local distribName=$(distribName.sh)

	if [ $osFamily = Linux ]; then
		if grep ID_LIKE /etc/os-release -q; then
			distribType=$(source /etc/os-release && echo $ID_LIKE)
		elif [ ls /etc/*_version >/dev/null 2>&1 ]; then
			distribType=$(echo /etc/*version | sed 's,/etc/\|_version,,g')
		else
			case $distribName in
				sailfishos|rhel|fedora|centos) distribType=redhat ;;
				ubuntu) distribType=debian;;
				*) distribType=$distribName ;;
			esac
		fi
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
