#!/usr/bin/env sh

string2qrcode ()
{
	local dotSize=7 url=""
	if [ $# = 1 ]; then
		url="$1"
		qrencode -l H -s $dotSize -o- "$url" | feh -
	fi
}

string2qrcode "$1"
