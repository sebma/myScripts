#!/usr/bin/env bash

dirName=$(dirname $0)
bluetoothController=$(hciconfig 2>/dev/null | awk -F: '/^\w+:/{print$1;exit}')
if [ -z "$bluetoothController" ]; then
	echo "=> ERROR: Could not detect any bluetooth controller." >&2
	exit 1
else
	echo "=> bluetoothController = $bluetoothController"
fi

if which bluetoothctl >/dev/null 2>&1; then
	echo "=> You are using BlueZ5." >&2

	bluetoothControllerMACAddress=$(printf "list\nquit\n" | bluetoothctl | awk /^Controller/'{print$2;exit}')
	if [ -z "$bluetoothControllerMACAddress" ]; then {
		echo "=> ERROR: Could not detect any bluetooth controller." >&2
		exit 2
	}
	fi

	echo "=> bluetoothControllerMACAddress = $bluetoothControllerMACAddress"

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
	
	command locate -r /module-bluetooth-discover.so$ | grep -q /module-bluetooth-discover.so$ || {
    	echo "=> ERROR: The <module-bluetooth-discover.so> needs to be installed." >&2
	    exit 5
	}

	pactl list modules | grep -q module-bluetooth-discover || pactl load-module module-bluetooth-discover

	deviceRegExp=$(sed "s/ /./g" <<< "$deviceRegExp")
	if echo "$deviceList" | grep -q "$deviceRegExp"; then {
		deviceHW=$(echo "$deviceList" | awk /^Device.*$deviceRegExp/'{print$2}' | sort -u)
		cat<<-EOF | bluetoothctl -a
	select $bluetoothControllerMACAddress
	power on
	default-agent
	pairable on
	pair $deviceHW
	connect $deviceHW
	info $deviceHW
	quit
EOF
		sleep 5

		$dirName/moveAudio2BlueToothSink.sh $deviceHW
	} else {
		echo "=> ERROR: The device you have chosen is not visible." >&2
		exit 5
	}
	fi
	
elif which hciconfig >/dev/null 2>&1; then
	echo "=> You are using BlueZ4." >&2

	if hciconfig $bluetoothController | grep -q DOWN;then
		echo "=> The <$bluetoothController> controller is DOWN, turning it on ..." >&2
		sudo hciconfig $bluetoothController up
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
		sudo -b rfcomm connect 0 $deviceHW 2>&1 | grep refused && exit 1
		sleep 5
		rfcomm show $deviceHW
		hcitool con

		$dirName/moveAudio2BlueToothSink.sh $deviceHW
	} else {
		echo "=> ERROR: The device you have chosen is not visible." >&2
		exit 5
	}
	fi
else
	echo "=> ERROR: BlueZ is not installed at all." >&2
	exit -1
fi
