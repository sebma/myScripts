#!/usr/bin/env bash

distribName () {
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	local osName=unknown
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
inxiInstall() {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo="command sudo" || local sudo=""
	local distribName=$(distribName)
	local retCode=0
	if [ $distribName = ubuntu ]; then
		grep -q "^deb .*unit193/inxi" /etc/apt/sources.list.d/*.list || $sudo add-apt-repository ppa:unit193/inxi -y
		apt-cache policy inxi | grep -q unit193/inxi || $sudo apt update
		dpkg -l inxi | grep -q ^.i || $sudo apt install -V inxi
	fi
}
toolsInstall () {
	echo "=> Checking the required tools ..."
	requiredTools="acpidump dmidecode hdparm hwinfo sensors lsb_release glxinfo lspci smartctl usb-devices xdpyinfo"
	for tool in $requiredTools;do
		if ! type -P $tool;then
			echo "=> WARNING : You must install the $tool tool."
		fi
	done
	echo
	echo "=> Checking the optional tools ..."
	optionalTools="alsa-info cpuid edid-decode ethtool fdisk i2cdetect iw memtester sar upower vainfo vdpauinfo vulkaninfo iwlist xrandr xinput"
	for tool in $optionalTools;do
		if ! type -P $tool;then
			echo "=> WARNING : You may install the $tool tool."
		fi
	done
	echo
}
hw_probeInstall () {
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && local sudo="command sudo" || local sudo=""
	local distribName=$(distribName)
	local retCode=0

	if [ $osFamily != Linux ];then
		echo "=> $distribName is not supported !"
		exit 1
	fi

	if [ $distribName = ubuntu ]; then
		local ubuntuSources=/etc/apt/sources.list
		local distribMajorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)
		grep -q universe $ubuntuSources   || $sudo add-apt-repository universe -y
		grep -q multiverse $ubuntuSources || $sudo add-apt-repository multiverse -y
		[ $distribMajorNumber -lt 20 ] && ! grep -q "^deb .*mikhailnov/hw-probe" /etc/apt/sources.list.d/*.list && $sudo add-apt-repository ppa:mikhailnov/hw-probe -y
		apt-cache policy hw-probe | grep -q mikhailnov/hw-probe || $sudo apt update
		dpkg -l hw-probe | grep -q ^.i || $sudo apt install -V hw-probe
		retCode=$?
	elif [ $distribName = arch ]; then
		if $sudo echo "";then
			$sudo pacman -Sy
			$sudo pacman -Fy

			type -P fakeroot >/dev/null 2>&1 || $sudo pacman -S fakeroot
			type -P strip >/dev/null 2>&1 || $sudo pacman -S binutils

			if ! type -P inxi >/dev/null 2>&1;then
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

			type -P make >/dev/null 2>&1 || $sudo pacman -S make

			if ! type -P hw-probe >/dev/null 2>&1;then
				cd hw-probe >/dev/null 2>&1 || { git clone https://aur.archlinux.org/hw-probe.git;cd hw-probe; }
				if git config remote.origin.url | grep -q /hw-probe;then
					sed -i "/^depends=/s/'edid-decode'//" PKGBUILD
					makepkg -si
					retCode=$?
					sync
					cd ->/dev/null
				else
					git clone https://aur.archlinux.org/hw-probe.git
				fi
			fi
		fi
	fi

	echo
	type -P hw-probe >/dev/null 2>&1 && $sudo sed -i "/inxi /s/inxi -[Fa-z]*/inxi -FJxxxzmd/" $(which hw-probe) && \hw-probe -v
	return $retCode
}

toolsInstall
inxiInstall
hw_probeInstall
