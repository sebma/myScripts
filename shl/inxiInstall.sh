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
inxiInstall () {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo=$(which sudo) || local sudo=""
	local distribName=$(distribName)
	local retCode=0
	if [ $distribName = ubuntu ]; then
		local ubuntuSources=/etc/apt/sources.list
		local distribMajorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
		grep -q universe $ubuntuSources   || $sudo add-apt-repository universe -y
		grep -q multiverse $ubuntuSources || $sudo add-apt-repository multiverse -y
		grep -q "^deb .*unit193/inxi" /etc/apt/sources.list.d/*.list || $sudo add-apt-repository ppa:unit193/inxi -y
		apt-cache policy inxi | grep -q unit193/inxi || $sudo apt update
		dpkg -l inxi | grep -q ^.i || $sudo apt install -V inxi
		retCode=$?
	elif [ $distribName = arch ]; then
		if $sudo echo "";then
			$sudo pacman -Sy
			$sudo pacman -Fy

			which fakeroot >/dev/null 2>&1 || $sudo pacman -S fakeroot
			which strip >/dev/null 2>&1 || $sudo pacman -S binutils

			if ! which inxi >/dev/null 2>&1;then
				cd inxi >/dev/null 2>&1 || { git clone https://aur.archlinux.org/inxi.git;cd inxi; }
				if git config remote.origin.url | grep -q /inxi;then
					makepkg -si
					retCode=$?
					sync
					cd ->/dev/null
				else
					git clone https://aur.archlinux.org/inxi.git
				fi
			fi
		fi
	fi

	echo
	which inxi >/dev/null 2>&1 && inxi -V
	return $retCode
}

inxiInstall
