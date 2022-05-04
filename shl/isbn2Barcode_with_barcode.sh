#!/usr/bin/env sh

ISBN2Barcode_with_barcode ()
{
	local string=""
	if [ $# = 1 ]; then
		string="$1"
		barcode -e ean-13 -S -b "$string" | mogrify -format png -resize 200% - | feh -
	fi
}

ISBN2Barcode_with_barcode "$1"
