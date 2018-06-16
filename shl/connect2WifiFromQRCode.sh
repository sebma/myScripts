#!/usr/bin/env bash

qrPictureFile=$1

test "$qrPictureFile" || {
	echo "=> Usage: $0 <qrPictureFile>" >&2
	exit 1
}

qrdecode="zbarimg -q --raw"
ssid=$($qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$3}')
pass=$($qrdecode "$qrPictureFile" | awk -F "[:;]" '{printf$7}')
test $ssid && test $pass && nmcli dev wifi connect "$ssid" password "$pass"
