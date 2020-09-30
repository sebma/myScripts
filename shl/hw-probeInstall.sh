#!/usr/bin/env bash

distribName ()
{
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if which lsb_release > /dev/null; then
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

distribName=$(distribName)
if [ $distribName = ubuntu ]; then
	ubuntuSources=/etc/apt/sources.list
	grep -q universe $ubuntuSources   || sudo add-apt-repository universe -y
	grep -q multiverse $ubuntuSources || sudo add-apt-repository multiverse -y
	grep -q "^deb .*unit193/inxi" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:unit193/inxi -y
	grep -q "^deb .*mikhailnov/hw-probe" /etc/apt/sources.list.d/*.list || sudo add-apt-repository ppa:mikhailnov/hw-probe -y
	apt-cache policy inxi | grep -q unit193/inxi || sudo apt update
	apt-cache policy hw-probe | grep -q mikhailnov/hw-probe || sudo apt update
	dpkg -l inxi | grep -q ^.i || sudo apt install -V inxi
	dpkg -l hw-probe | grep -q ^.i || sudo apt install -V hw-probe
elif [ $distribName = arch ]; then
fi
