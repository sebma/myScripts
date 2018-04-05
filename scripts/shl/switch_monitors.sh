#!/bin/sh -eu

screenList="`xrandr | awk '/ connected/{print$1}'`"
nbScreens=`echo "$screenList" | wc -l`

test $nbScreens != "2" && {
  echo "=> nbScreens = $nbScreens"
  echo "=> Il faut exactement 2 ecrans"
  exit 1
}

currentMonitor=`xrandr --verbose | egrep -B7 "CRTC:.*0" | awk '/connected/{print$1}'`
echo "=> currentMonitor = $currentMonitor"
targetMonitor=`echo "$screenList" | grep -v $currentMonitor`
echo "=> targetMonitor = $targetMonitor"

xrandr --output $targetMonitor --primary
