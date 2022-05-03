#!/usr/bin/env bash

distribName () {
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if type -P lsb_release >/dev/null 2>&1; then
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
inxiInstallFromSource () {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo="command sudo" || local sudo=""
	local inxiGitREPO=https://github.com/smxi/inxi

	local forceInstall=false
	test $# != 0 && [ "$1" == "-f" ] && forceInstall=true
	if type -P inxi >/dev/null 2>&1 && ! $forceInstall; then
		echo "=> INFO [$FUNCNAME] : inxi is already installed." 1>&2
		return 1
	fi

	if ! type -P git >/dev/null 2>&1; then
		echo "=> ERROR [$FUNCNAME] : You must first install <git>." 1>&2
		return 2
	fi

	local prevDIR=$PWD
	local retCode=0
	mkdir -p ~/git/linuxhw
	if cd ~/git/linuxhw;then
		git clone $inxiGitREPO
		if cd $(basename $inxiGitREPO);then
			pwd
			git pull
			$sudo install -vpm 755 inxi /usr/local/ || install -vpm 755 inxi ~/myScripts/pl/not_mine/
			retCode=$?
			echo
		fi
	fi

	sync
	cd $prevDIR
	type -P inxi && inxi -V
	return $retCode
}

inxiInstallFromSource "$@"
