#!/usr/bin/env sh

string2qrcode ()
{
	local dotSize=7 string=""
	if [ $# = 1 ]; then
		string="$1"
		qrencode -l H -s $dotSize -o- "$string" | feh -
	fi
}

string2qrcode "$1"
