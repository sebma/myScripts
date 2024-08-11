#!/usr/bin/env bash

function distribType {
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if grep ID_LIKE /etc/os-release -q 2>/dev/null; then
			distribType=$(source /etc/os-release && echo $ID_LIKE)
		elif [ ls /etc/*_version >/dev/null 2>&1 ]; then
			distribType=$(echo /etc/*version | sed 's,/etc/\|_version,,g')
		else
			distribName=$(distribName.sh)
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
		test -n $OSTYPE && distribType=$OSTYPE || distribType=$osFamily
	fi

	echo $distribType
}

distribType
