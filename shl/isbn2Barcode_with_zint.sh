#!/usr/bin/env sh

ISBN2Barcode_with_zint ()
{
	local string=""
	if [ $# = 1 ]; then
		string="$1"
		zint -b ISBNX --scale 2 --direct -d "$string" | feh -
	fi
}

ISBN2Barcode_with_zint "$@"
