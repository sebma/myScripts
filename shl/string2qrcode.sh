#!/usr/bin/env sh

string2qrcode ()
{
	local dotSize=8 string=""
	if [ $# = 1 ]; then
		string="$1"
		qrencode -l H -s $dotSize -m 0 -o- "$string" | feh -
	fi
}

string2qrcode "$1"
