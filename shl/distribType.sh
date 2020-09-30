#!/usr/bin/env bash

distribType ()
{
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	distribName=$(distribName.sh)

	if which lsb_release > /dev/null 2>&1; then
		distribName=$(\lsb_release -si)
		case $distribName in
			Ubuntu|Debian) distribType=debian ;;
			Mer|Redhat|Fedora) distribType=redhat ;;
			*) distribType=unknown ;;
		esac
	elif [ $distribType = unknown ]; then
		if [ $osFamily = Linux ]; then
			distribType=$(source /etc/os-release && echo $ID_LIKE | cut -d'"' -f2 | cut -d" " -f1)
			if [ -z "$distribType" ]; then
				distribName=$(source /etc/os-release;echo $ID)
				case $distribName in
					sailfishos|rhel|fedora|centos) distribType=redhat ;;
					arch|gentoo) distribType=arch ;;
					*) distribType=unknown ;;
				esac
			fi
		else
			if [ $osFamily = Darwin ]; then
				distribName="$(sw_vers -productName)"
				distribType=Darwin
			else
				distribName=unknown
				distribType=$osFamily
			fi
		fi
	fi
	echo $distribType
}

distribType
