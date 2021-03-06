#!/usr/bin/env bash

qrPictureFile=$1

if test -z "$qrPictureFile"
then
	echo "=> Usage: $0 <qrPictureFile>" >&2
	exit 1
fi

if ! zbarimg -h >/dev/null
then
	echo "=> ERROR: $0: zbarimg is not installed." >&2
	exit 2
fi

qrdecode="zbarimg -q --raw"
ssid=$( $qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$3}')

os=$(uname -s)
if [ $os = Linux ] || [ $os = Darwin ]
then
	pass=$($qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$7}')
	echo "$pass"
	if [ -z $ssid ] || [ -z $pass ]
	then
		echo "=> ERROR: The <ssid> or the <pass> variable is an empty string." >&2
		exit 2
	fi
fi

if [ $os = Linux ]
then
	set -x
	isHidden="$($qrdecode "$qrPictureFile" | grep -q ';H:true;' && echo true || echo false)"
	if $isHidden
	then
		nmcli dev wifi connect "$ssid" password "$pass" name $ssid hidden yes
	else
		nmcli dev wifi connect "$ssid" password "$pass" name $ssid
	fi
	set +x
elif [ $os = Darwin ]
then
	interFace=$(networksetup -listallhardwareports | awk '/Wi-Fi/{found=1}/Device/&&found{print$NF;exit}')
	networksetup -setairportnetwork $interFace "$ssid" "$pass"
fi
