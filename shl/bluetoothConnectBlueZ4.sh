#!/usr/bin/env sh

bluetoothController=$(hciconfig | awk  '/^\w+:/{sub(":","");print$1}')
if [ -z "$bluetoothController" ]; then {
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 2
}
fi
echo "=> bluetoothController = $bluetoothController"
sudo hciconfig $bluetoothController up

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
echo "$deviceList" | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f2-
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

if echo "$deviceList" | tr '\t' ' ' | tr -s ' ' | cut -d' ' -f2- | grep -q "$deviceName"; then {
	deviceHW=$(echo "$deviceList" | awk /$deviceName/'{print$1}')
	sudo hcitool cc $deviceHW
	sudo -b rfcomm connect 0 $deviceHW
	rfcomm show $deviceHW
	hcitool con
} else {
	echo "=> ERROR: The device you have chosen is not visible." >&2
	exit 5
}
fi
