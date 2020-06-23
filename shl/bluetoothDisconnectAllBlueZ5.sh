#!/usr/bin/env bash

bluetoothController=$(hciconfig 2>/dev/null | awk -F: '/^\w+:/{print$1;exit}')
if [ -z "$bluetoothController" ]; then
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 1
else
	hciconfig $bluetoothController | grep -q DOWN && sudo hciconfig $bluetoothController up
	echo "=> bluetoothController = $bluetoothController"
fi

if ! which bluetoothctl >/dev/null 2>&1; then {
	echo "=> ERROR: You must install BlueZ v5." >&2
	exit 2
}
fi

if which bt-device >/dev/null 2>&1;then
	devices=$(bt-device -l | grep -vw "Added devices" | awk -F "[()]" '{print$(NF-1)}')
else
	devices=$(echo | bluetoothctl 2>/dev/null | awk '/\<Device\>/{print$4}')
fi

if [ -z "$devices" ]; then
	echo "=> ERROR: Could not find any device." >&2
	exit 3
fi

echo "$devices" | while read device
do
	set -x
	echo disconnect $device | bluetoothctl
	set +x
done

moveAudio2HDMI.sh
