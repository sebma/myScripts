#!/usr/bin/env bash

if [ -z "$SSH_CONNECTION" ];then
	echo "=> xrandr | grep connected ..."
	xrandr | grep connected

	for EDID in $(ls /sys/class/drm/*/edid)
	do
		text=$(tr -d '\0' <"$EDID")
		[ -n "$text" ] && echo "=> edid-decode < $EDID | egrep 'Manufacturer:|Product|Alphanumeric' ..." && edid-decode < $EDID | egrep 'Manufacturer:|Product|Alphanumeric'
		sleep 0.0001s
	done | more

	#xrandr --verbose | edid-decode | egrep 'Manufacturer:|Product|Alphanumeric'
	echo "=> xrandr --props | edid-decode | egrep 'Manufacturer:|Product|Alphanumeric' ..."
	xrandr --props | edid-decode | egrep 'Manufacturer:|Product|Alphanumeric'
else
	echo "=> You cannot use <${0/*\//}> through SSH." >&2
	exit 1
fi
