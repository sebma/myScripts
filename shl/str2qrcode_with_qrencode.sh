#!/usr/bin/env bash

string2qrcode_with_qrencode () {
	local dotSize=8 string=""
	local width=1600
	local heigth=900
	if [ $# != 1 ]; then
		echo "=> Usage $FUNCNAME stringOrURL" >&2
		return -1
	else
		string="$1"
		qrencode -l H -s $dotSize -m 0 -o- "$string" | feh -g +$((($width-$dotSize)/2))+$((($heigth-$dotSize)/2)) -
	fi
}

string2qrcode_with_qrencode "$@"
