#!/usr/bin/env bash

function moveAudioToAnalogStereo {
	set -x
	echo "=> BEFORE :"
	pactl list short sink-inputs

	analogStereoOutputPattern='\.analog-stereo\>'
	sink_output=$(pactl list short sinks | awk "/$analogStereoOutputPattern/"'{printf$1}')
	pactl list short sink-inputs | awk '/protocol-native.c/{print$1}' | while read sink_input
	do
		pactl move-sink-input $sink_input $sink_output
	done

	echo "=> AFTER :"
	pactl list short sink-inputs
	set +x
}

moveAudioToAnalogStereo "$@"
