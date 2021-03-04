#!/usr/bin/env bash

dirName=$(dirname $0)
bluetoothController=$(hciconfig 2>/dev/null | awk -F: '/^\w+:/{print$1;exit}')
if [ -z "$bluetoothController" ]; then
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 1
else
	echo "=> bluetoothController = $bluetoothController"
fi

if ! which bluetoothctl >/dev/null 2>&1; then {
	echo "=> ERROR: You must install BlueZ v5." >&2
	exit 2
}
fi

if devices=$(bt-device -l 2>/dev/null | grep -vw "Added devices");then
	devices=$(echo "$devices" | awk -F "[()]" '{print$(NF-1)}')
else
	devices=$(echo devices | bluetoothctl 2>/dev/null | awk '/^Device\>/{print$2}')
fi

if [ -z "$devices" ]; then
	echo "=> ERROR: Could not find any device." >&2
	exit 3
fi

echo power on | bluetoothctl >/dev/null 2>&1
echo "$devices" | while read device
do
	set -x
	echo info $device | bluetoothctl 2>/dev/null | \grep -q 'Connected: yes' && echo disconnect $device | bluetoothctl 2>/dev/null
	set +x
done

echo $HOSTNAME | egrep -qi B206 && $dirName/moveAudio2HDMI.sh || $dirName/moveAudio2AnalogStereo.sh
