#!/usr/bin/env bash

xsetDPI () { 
	local output=$(xrandr | awk  '/^.+ connected/{print$1}')
	local oldDPI=$(xfconf-query -c xsettings -p /Xft/DPI)
	local newDPI=$1
	if [ -z $oldDPI ]; then
		echo "=> Could not infer the current DPI." >&2
	else		
		echo "=> Reset current DPI command :"
		echo "xfconf-query -c xsettings -p /Xft/DPI -s $oldDPI"
	fi
	if [ -z $newDPI ]; then
		echo "=> Current DPI: $oldDPI"
		echo "=> Usage: $FUNCNAME XResxYRes"
		return 2
	else
		echo "=> Setting new resolution command :"
		echo "xfconf-query -c xsettings -p /Xft/DPI -s $newDPI"
		xfconf-query -c xsettings -p /Xft/DPI -s $newDPI
	fi
}

#xdpyinfo | grep dots
#xrandr --dpi $1

xsetDPI $@
xfce4-appearance-settings &
