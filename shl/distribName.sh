#!/usr/bin/env bash

distribName () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if ! lsb_release -si 2>/dev/null | grep -i "n/a" -q; then
			osName=$(lsb_release -si | awk '{print tolower($0)}')
		elif type -P hostnamectl >/dev/null 2>&1; then
			osName=$(hostnamectl status | awk '/Operating System/{print tolower($3)}')
		elif grep -w ID /etc/os-release -q 2>/dev/null; then
			osName=$(source /etc/os-release && echo $ID)
		elif [ -s /etc/issue.net ]; then
			osName=$(awk '{print tolower($1)}' /etc/issue.net)
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

distribName
