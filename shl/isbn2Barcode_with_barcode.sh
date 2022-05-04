#!/usr/bin/env sh

ISBN2Barcode_with_barcode ()
{
	local string="" stringLength=0
	if [ $# = 1 ]; then
		string="$1"
		stringLength="${#string}"
		echo "=> stringLength = $stringLength"
		if [ $stringLength = 10 ];then
			barcode -e isbn -S -b "$string" | mogrify -format png -resize 200% - | feh -
		elif [ $stringLength = 13 ];then
			barcode -e ean-13 -S -b "$string" | mogrify -format png -resize 200% - | feh -
		fi
	fi
}

ISBN2Barcode_with_barcode "$1"
