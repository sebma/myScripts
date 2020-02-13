#!/usr/bin/env sh

bluetoothController=$(hciconfig 2>/dev/null | awk -F: '/^\w+:/{print$1;exit}')
if [ -z "$bluetoothController" ]; then
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 1
else
	hciconfig hci0 | grep -q DOWN && sudo hciconfig $bluetoothController up
	echo "=> bluetoothController = $bluetoothController"
fi

if ! which bluetoothctl >/dev/null 2>&1; then {
	echo "=> ERROR: You must install BlueZ v5." >&2
	exit 2
}
fi

deviceList=$(echo | bluetoothctl 2>&1 | grep -w Device)
if [ -z "$deviceList" ]; then {
	echo "=> ERROR: Could not find any device." >&2
	exit 3
}
fi

echo "$deviceList" | awk '/\<Device\>/{print$4}' | while read device
do
	set -x
	echo disconnect $device | bluetoothctl
	set +x
done
