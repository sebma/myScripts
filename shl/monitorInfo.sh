#!/usr/bin/env bash

set -x
for EDID in $(ls /sys/class/drm/*/edid)
do
	parse-edid < $EDID
done | more
xrandr | grep connected
set +x
