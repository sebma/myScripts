#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo="command sudo" || sudo=""
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

searchPackagesFromFilePath() {
	packagesList=""
	distribName=$(distribName)
	if [ $distribName = ubuntu ] || [ $distribName = debian ]; then
		dpkg -l apt-file | grep -q ^.i || $sudo apt install -V apt-file -y
		$sudo apt-file update
		for tool
		do
			packagesList+="$(apt-file -x search "/bin/$tool" | cut -d: -f1) "
		done
	elif [ $distribName = arch ]; then
		for tool
		do
			packagesList+="$(pacman -F /usr/bin/$tool | awk '/ is /{printf$(NF-1)}') "
		done
	fi

	echo "$packagesList"
}

searchPackagesFromFilePath "$@"
