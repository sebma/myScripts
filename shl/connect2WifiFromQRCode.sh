#!/usr/bin/env bash

qrPictureFile=$1

test "$qrPictureFile" || {
	echo "=> Usage: $0 <qrPictureFile>" >&2
	exit 1
}

os=$(uname -s)
qrdecode="zbarimg -q --raw"
ssid=$($qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$3}')
pass=$($qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$7}')

if [ -z $ssid ] || [ -z $pass ]
then
	echo "=> ERROR: The <ssid> or the <pass> is an empty string." >&2
	exit 2
fi

if   [ $os = Linux ]
then
	nmcli dev wifi connect "$ssid" password "$pass"
elif [ $os = Darwin ]
then
	interFace=$(networksetup -listallhardwareports | awk '/Wi-Fi/{found=1}/Device/&&found{print$NF;exit}')
	networksetup -setairportnetwork $interFace "$ssid" "$pass"
fi
