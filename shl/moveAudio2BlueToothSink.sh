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
		! pactl list sinks short >/dev/null 2>&1 && test "$SSH_CONNECTION" && pax11publish -r
		bluetoothSinkVisible=$(pactl list sources short | grep -q $bluetoothDeviceMacAddrPACTLString && echo true || echo false)
		if [ $bluetoothSinkVisible = true ];then
			echo "=> BEFORE :"
			pactl list sink-inputs short

			sink_output=$(pactl list sources short | awk "/$bluetoothDeviceMacAddrPACTLString/"'{printf$1}')
			echo "=> sink_output = $sink_output"
			pactl list sink-inputs short | awk '/protocol-native.c/{print$1}' | while read sink_input
			do
				pactl move-sink-input $sink_input $sink_output
			done
			pactl suspend-sink bluez_sink.$bluetoothDeviceMacAddrPACTLString 0

			echo "=> AFTER :"
			pactl list sink-inputs short
		else
			echo "=> ERROR : There is no audio sink for $bluetoothDeviceMacAddr" >&2
			exit 1
		fi
	fi
}

moveAudioToBluetoothSink "$@"
