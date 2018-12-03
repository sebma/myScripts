#!/usr/bin/env sh

xsetResolution () { 
	local output=$(\xrandr | \awk  '/^.+ connected/{print$1}')
	local oldResolution=$(\xrandr | \awk '/[0-9].*\*/{print$1}')
	local newResolution=$1
	echo "=> Reset current resolution command :"
	echo "\xrandr --output $output --mode $oldResolution"
	if [ -z $newResolution ]; then
		xrandr
		echo "=> Usage: $FUNCNAME XResxYRes"
		return 1
	else
		if ! \xrandr | grep --color=auto -wq $newResolution; then
			echo "=> $FUNCNAME ERROR : The resolution <$newResolution> is not supported." 1>&2
			return 2
		fi
		echo "=> Setting new resolution command :"
		echo "\xrandr --output $output --mode $newResolution"
		\xrandr --output $output --mode $newResolution
	fi
}

xsetResolution $@
