#!/usr/bin/env bash

xrandr | grep connected
echo
for EDID in $(ls /sys/class/drm/*/edid)
do
	text=$(tr -d '\0' <"$EDID")
	[ -n "$text" ] && edid-decode < $EDID | egrep "Manufacturer:|Product"
	sleep 0.0001s
done | more
