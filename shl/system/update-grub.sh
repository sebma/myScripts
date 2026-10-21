#!/usr/bin/env bash

function distribName {
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s | cut -d' ' -f1)

	if [ $osFamily = Linux ]; then
		if grep -w ID /etc/os-release -q 2>/dev/null; then
			osName=$(source /etc/os-release && echo $ID)
		elif [ -s /etc/issue.net ]; then
			osName=$(awk '{print tolower($1)}' /etc/issue.net)
		elif ! lsb_release -si 2>/dev/null | grep -i "n/a" -q; then
			osName=$(lsb_release -si | awk '{print tolower($0)}')
		elif type -P hostnamectl >/dev/null 2>&1; then
			osName=$(hostnamectl status | awk '/Operating System/{print tolower($3)}')
		fi
	elif [ $osFamily = Darwin ]; then
		osName="$(sw_vers -productName)"
	elif [ $osFamily = Android ]; then
		osName=Android
	elif [ $osFamily = VMkernel ]; then # ESXi
		osName=ESXi
	else
		test -n $OSTYPE && osName=$OSTYPE || osName=$osFamily
	fi

	echo $osName | awk '{print tolower($0)}'
}

function distribFamily {
	local distribName=unknown
	local distribFamily=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s | cut -d' ' -f1)

	if [ $osFamily = Linux ]; then
		if grep ID_LIKE /etc/os-release -q 2>/dev/null; then
			distribFamily=$(source /etc/os-release && echo $ID_LIKE)
		elif [ ls /etc/*_version >/dev/null 2>&1 ]; then
			distribFamily=$(echo /etc/*version | sed 's,/etc/\|_version,,g')
		else
			distribName=$(distribName)
			case $distribName in
				sailfishos|rhel|fedora|centos|rocky|photon) distribFamily=redhat ;;
				ubuntu) distribFamily=debian;;
				*) distribFamily=$distribName ;;
			esac
		fi
	elif [ $osFamily = Darwin ]; then
		distribFamily=Darwin
	elif [ $osFamily = Android ]; then
		distribFamily=Android
	elif [ $osFamily = VMkernel ]; then # ESXi
		distribFamily=ESXi
	else
		test -n $OSTYPE && distribFamily=$OSTYPE || distribFamily=$osFamily
	fi

	echo $distribFamily
}

distribFamily=$(distribFamily)
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)

case $distribFamily in
	rhel*|redhat)
		if [ -d /sys/firmware/efi ];then
			$sudo grub2-mkconfig -o "$(readlink -f /etc/grub2-efi.cfg)" || $sudo grub2-mkconfig -o "$(readlink -f /etc/grub2-efi.conf)"
		else
			$sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.cfg)" || $sudo grub2-mkconfig -o "$(readlink -f /etc/grub2.conf)"
		fi
	;;
	debian) $sudo update-grub;;
	*) echo "=> $distribFamily not supported yet." >&2;exit 1;;
esac
