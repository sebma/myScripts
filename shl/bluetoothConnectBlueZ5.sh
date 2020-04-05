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

bluetoothControllerMACAddress=$(printf "list\nquit\n" | bluetoothctl | awk /^Controller/'{print$2;exit}')

deviceList=$(printf "power on\nscan on\ndevices\nquit\n" | bluetoothctl | grep ^Device | sed 's/^.* Device/Device/')
if [ -z "$deviceList" ]; then {
	echo "=> ERROR: Could not find any device to connect to." >&2
	exit 3
}
fi

printf "Here are the available devices : "
echo "$deviceList" | awk '/^Device/{print$NF}'
if [ $# = 0 ]; then {
	printf "Type the device name you want to connect to : "
	read deviceName
	if [ -z "$deviceName" ]; then {
		echo "=> ERROR: The device name you typed is empty." >&2
		exit 4
	}
	fi
} else {
	deviceName=$1
}
fi

if echo "$deviceList" | grep -q "$deviceName"; then {
	deviceHW=$(echo "$deviceList" | awk /^Device.*$deviceName/'{print$2}' | sort -u)
	cat<<EOF | bluetoothctl -a
select $bluetoothControllerMACAddress
power on
default-agent
pairable on
pair $deviceHW
trust $deviceHW
paired-devices
connect $deviceHW
info $deviceHW
quit
EOF
} else {
	echo "=> ERROR: The device you have chosen is not visible." >&2
	exit 5
}
fi
