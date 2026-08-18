#!/usr/bin/env bash

string2qrcode_with_qrencode () {
	local dotSize=8 string=""
	local width=0
	local heigth=0

	if [ $# != 1 ]; then
		echo "=> Usage $FUNCNAME stringOrURL" >&2
		return -1
	else
		read width heigth <<< $(xrandr | awk '-Fx| *' '/\+([^0]|$)/{printf$2" "$3;exit}')
		string="$1"
		qrencode -l H -s $dotSize -m 0 -o- "$string" | feh -g +$((($width-$dotSize)/2))+$((($heigth-$dotSize)/2)) -
	fi
}

string2qrcode_with_qrencode "$@"
