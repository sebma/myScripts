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

searchPackages() {
	packagesList=""
	distribName=$(distribName)
	if [ $distribName = ubuntu ] || [ $distribName = debian ]; then
		dpkg -l apt-file | grep -q ^.i || $sudo apt install -V apt-file -y
		$sudo apt-file update
		for tool
		do
			packagesList+="$(apt-file search /bin/$tool | cut -d: -f1) "
		done
	elif [ $distribName = arch ]; then
		:
	fi

	echo "$packagesList"
}

searchPackages "$@"
