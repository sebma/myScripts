#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo=$(which sudo) || sudo=""
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

updateLinuxDistribRepos() {
	distribName=$(distribName)
	if [ $distribName = ubuntu ]; then
		ubuntuSources=/etc/apt/sources.list
		for repo in main restricted universe multiverse
		do
			grep -q $repo $ubuntuSources || $sudo add-apt-repository $repo -y
		done
		$sudo apt update -V
	elif [ $distribName = arch ]; then
		$sudo pacman -Sy
		$sudo pacman -Fy
	fi
}

installPackages() {
	packagesList="$@"
	distribName=$(distribName)
	if [ $distribName = ubuntu ] || [ $distribName = debian ]; then
		$sudo apt install -V $packagesList
	elif [ $distribName = arch ]; then
		$sudo pacman -S $packagesList
	fi
}

installPackages "$@"
