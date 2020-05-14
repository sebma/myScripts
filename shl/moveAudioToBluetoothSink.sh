#!/usr/bin/env bash

function moveAudioToBluetoothSink {
	( [ $# != 1 ] || echo $1 | egrep -q -- "^--?(h|u)" ) && echo "=> Usage : $FUNCNAME bluetoothDeviceName|bluetoothDeviceMacAddr" 1>&2 && return 1
	local firstArg=$1
	local bluetoothDeviceName=null
	local bluetoothDeviceMacAddr=null

	if echo $firstArg | grep -q :; then
		bluetoothDeviceMacAddr=$firstArg 
	else
		bluetoothDeviceName=$firstArg
	fi

	bluetoothDeviceMacAddr=$(echo | bluetoothctl 2>/dev/null | awk "/Device.*($bluetoothDeviceMacAddr|$bluetoothDeviceName)/"'{print$4;exit}')
	if [ -n "$bluetoothDeviceMacAddr" ];then
		bluetoothDeviceMacAddrPACTLString=$(echo $bluetoothDeviceMacAddr | sed s/:/_/g)
		pactl list short sinks >/dev/null 2>&1 || pax11publish -r
		connectToBluetoothSink=$(pactl list short sinks | grep -q $bluetoothDeviceMacAddrPACTLString && echo true || echo false)
		if [ $connectToBluetoothSink = true ];then
			echo "=> BEFORE :"
			pactl list short sink-inputs

			sink_output=$(pactl list short sinks | awk "/$bluetoothDeviceMacAddrPACTLString/"'{printf$1}')
			echo "=> sink_output = $sink_output"
			pactl list short sink-inputs | awk '/protocol-native.c/{print$1}' | while read sink_input
			do
				pactl move-sink-input $sink_input $sink_output
			done

			echo "=> AFTER :"
			pactl list short sink-inputs
		else
			echo "=> ERROR : There is no audio sink for $bluetoothDeviceMacAddr" >&2
			exit 1
		fi
	fi
}

moveAudioToBluetoothSink "$@"
