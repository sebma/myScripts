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
hw-probeInstallFromSource () {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo=$(which sudo) || local sudo=""
	local distribName=$(distribName)
	local hw-probeGitREPO=https://github.com/linuxhw/hw-probe

	if ! which git > /dev/null 2>&1; then
		echo "=> ERROR [$FUNCNAME] : You must first install <git>." 1>&2;
		return 1
	fi

	local prevDIR=$PWD
	mkdir -p git/linuxhw
	if cd git/linuxhw;then
		git clone $https://github.com/linuxhw/hw-probe
		if cd hw-probe;then
			$sudo make install prefix=/usr/local
		fi
	fi
	cd $prevDIR
}

hw-probeInstallFromSource
