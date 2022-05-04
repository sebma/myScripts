#!/usr/bin/env sh

string2qrcode ()
{
	local dotSize=8 string=""
	if [ $# = 1 ]; then
		string="$1"
		zint -b 58 --scale 4 --secure 8 --direct -d "$string" | feh -
	fi
}

string2qrcode "$1"
