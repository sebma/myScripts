#!/usr/bin/env bash

string2qrcode_with_qrencode () {
	local dotSize=8 string=""
	local width=$(xrandr | awk '-Fx| *' '/\+([^0]|$)/{printf$2;exit}')
	local heigth=$(xrandr | awk '-Fx| *' '/\+([^0]|$)/{printf$3;exit}')
	if [ $# != 1 ]; then
		echo "=> Usage $FUNCNAME stringOrURL" >&2
		return -1
	else
		string="$1"
		qrencode -l H -s $dotSize -m 0 -o- "$string" | feh -g +$((($width-$dotSize)/2))+$((($heigth-$dotSize)/2)) -
	fi
}

string2qrcode_with_qrencode "$@"
