#!/usr/bin/env sh

string2qrcode_with_zint ()
{
	# https://www.zint.org.uk/manual
	local dotSize=8 string=""
	if [ $# = 1 ]; then
		string="$1"
		zint -b QRCODE --scale 4 --secure 4 --direct -d "$string" | feh -
	fi
}

string2qrcode_with_zint "$1"
