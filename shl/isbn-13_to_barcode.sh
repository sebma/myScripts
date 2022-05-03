#!/usr/bin/env sh

ISBN2Barcode ()
{
	local string=""
	if [ $# = 1 ]; then
		string="$1"
		barcode -e ean-13 -S -b "$string" | mogrify -format png -sample 200% - | feh -
	fi
}

ISBN2Barcode "$1"
