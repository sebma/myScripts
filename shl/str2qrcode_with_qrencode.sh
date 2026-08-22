#!/usr/bin/env bash

string2qrcode_with_qrencode () {
	local dotSize=8 string=""
	local width=0
	local heigth=0
	local osFamily=$(uname -s)

	if [ $# != 1 ]; then
		echo "=> Usage $FUNCNAME stringOrURL" >&2
		return -1
	else
		string="$1"
		if [ $osFamily == Linux ];then
			read width heigth <<< $(xrandr 2>/dev/null | awk -F'x| *' '/\+([^0]|$)/{printf$2" "$3;exit}')
		elif [ $osFamily == Darwin ];then
			:
		fi
		qrencode -l H -s $dotSize -m 0 -o- "$string" | feh -g +$((($width-$dotSize)/2))+$((($heigth-$dotSize)/2)) -
	fi
}

string2qrcode_with_qrencode "$@"
