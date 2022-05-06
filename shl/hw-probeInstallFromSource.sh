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
hw_probeInstallFromSource () {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo="command sudo" || local sudo=""
	local hw_probeGitREPO=https://github.com/linuxhw/hw-probe

	local forceInstall=false
	test $# != 0 && [ "$1" == "-f" ] && forceInstall=true
	if type -P hw-probe >/dev/null 2>&1 && ! $forceInstall; then
		echo "=> INFO [$FUNCNAME] : hw-probe is already installed." 1>&2
		return 1
	fi

	if ! type -P git >/dev/null 2>&1; then
		echo "=> ERROR [$FUNCNAME] : You must first install <git>." 1>&2
		return 2
	fi

	local prevDIR=$PWD
	local retCode=0
	if wget --no-config -N -P /tmp/myTmp/ -nv https://github.com/linuxhw/hw-probe/raw/master/hw-probe.pl; then
		sudo -v || sudo=""
		if [ -n "$sudo" ]; then
			$sudo install -Dvpm 755 /tmp/myTmp/hw-probe.pl /usr/local/bin/hw-probe
		else
			install -Dvpm 755 /tmp/myTmp/hw-probe.pl ~/myScripts/pl/not_mine/hw-probe
		fi
		retCode=$?
	fi

	sync
	cd $prevDIR
	type -P hw-probe >/dev/null 2>&1 && $sudo sed -i "/inxi /s/inxi -[Fa-z]*/inxi -FZxxxzmd/" $(which hw-probe) && \hw-probe -v
	return $retCode
}

hw_probeInstallFromSource "$@"
