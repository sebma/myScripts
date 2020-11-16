#!/usr/bin/env bash

scriptDir=$(dirname $0)
scriptDir=$(cd $scriptDir;pwd)
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
	cat<<-EOF | bluetoothctl
	select $bluetoothControllerMACAddress
	power on
	default-agent
	pairable on
	pair $deviceHW
	connect $deviceHW
EOF

	timeout=5s
	echo "=> Sleeping $timeout to let $1 finishing connecting to $HOSTNAME ..."
	sleep $timeout
	echo info $deviceHW | bluetoothctl | grep -v UUID:

	$scriptDir/moveAudio2BlueToothSink.sh $deviceHW
} else {
	echo "=> ERROR: The device you have chosen is not visible." >&2
	exit 5
}
fi
