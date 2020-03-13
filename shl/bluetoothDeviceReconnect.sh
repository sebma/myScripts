#!/usr/bin/env bash

function bluetoothDeviceReconnect {
	( [ $# != 1 ] || echo $1 | egrep -q -- "^--?(h|u)" ) && echo "=> Usage : $FUNCNAME bluetoothDeviceName|bluetoothDeviceMacAddr" 1>&2 && return 1
	local firstArg=$1
	local bluetoothDeviceName=null
	local bluetoothDeviceMacAddr=0

	if echo $firstArg | grep -q :; then
		bluetoothDeviceMacAddr=$firstArg 
	else
		bluetoothDeviceName=$firstArg
	fi

	bluetoothDeviceMacAddr=$(echo | bluetoothctl 2>/dev/null | awk "/Device.*($bluetoothDeviceMacAddr|$bluetoothDeviceName)/"'{print$4;exit}')
	if [ -n "$bluetoothDeviceMacAddr" ];then
		set -x
		echo disconnect $bluetoothDeviceMacAddr | bluetoothctl 2>/dev/null
		sleep 3
		echo connect $bluetoothDeviceMacAddr | bluetoothctl 2>/dev/null
		set +x
	fi
}

bluetoothDeviceReconnect "$@"
