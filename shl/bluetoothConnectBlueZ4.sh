#!/usr/bin/env bash

bluetoothController=$(hciconfig 2>/dev/null | awk -F: '/^\w+:/{print$1;exit}')
if [ -z "$bluetoothController" ]; then
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 1
else
	hciconfig hci0 | grep -q DOWN && sudo hciconfig $bluetoothController up
	echo "=> bluetoothController = $bluetoothController"
fi

deviceList=$(echo "=> Scanning for bluetooth devices ..." 1>&2;time -p hcitool scan | grep -v Scanning)
if [ -z "$deviceList" ]; then {
	deviceList=$(echo "=> Scanning deeper for bluetooth devices ..." 1>&2;time -p hcitool scan | grep -v Scanning)
	if [ -z "$deviceList" ]; then {
		echo "=> ERROR: Could not find any device to connect to." >&2
		exit 3
	}
	fi
}
fi

printf "Here are the available devices : "
deviceList="$(echo "$deviceList" | tr '\t' ' ' | tr -s ' ')"
echo "$deviceList" | cut -d' ' -f3-
if [ $# = 0 ]; then {
	printf "Type the device name you want to connect to : "
	read deviceRegExp
	if [ -z "$deviceRegExp" ]; then {
		echo "=> ERROR: The device name you typed is empty." >&2
		exit 4
	}
	fi
} else {
	deviceRegExp=$1
}
fi

deviceRegExp=$(sed "s/ /./g" <<< "$deviceRegExp")
if echo "$deviceList" | grep -q "$deviceRegExp"; then {
	deviceHW=$(echo "$deviceList" | awk /$deviceRegExp/'{print$1}')
	sudo hcitool cc $deviceHW
	sudo -b rfcomm connect 0 $deviceHW
	sleep 1
	rfcomm show $deviceHW
	hcitool con
} else {
	echo "=> ERROR: The device you have chosen is not visible." >&2
	exit 5
}
fi
