#!/usr/bin/env sh

distribName () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if which lsb_release >/dev/null 2>&1; then
			osName=$(lsb_release -si | awk '{print tolower($0)}')
			[ $osName = "n/a" ] && osName=$(source /etc/os-release && echo $ID)
		elif [ -s /etc/os-release ]; then
			osName=$(source /etc/os-release && echo $ID)
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

distribName
