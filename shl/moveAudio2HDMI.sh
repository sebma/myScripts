#!/usr/bin/env bash

function moveAudioToHDMI {
	echo "=> BEFORE :"
	! pactl list sinks short >/dev/null 2>&1 && test "$SSH_CONNECTION" && pax11publish -r
	pactl list sink-inputs short

	hdmiOutputPattern='\.hdmi-stereo\>'
	sink_output=$(pactl list sinks short | awk "/$hdmiOutputPattern/"'{printf$1}')
	if [ -z "$sink_output" ];then
		echo "=> Restarting pulseaudio server ..." >&2
		pulseaudio --kill && pgrep -a pulseaudio
		sink_output=$(pactl list sinks short | awk "/$hdmiOutputPattern/"'{printf$1}')
	fi
	echo "=> sink_output = $sink_output"
	pactl list sink-inputs short | awk '/protocol-native.c/{print$1}' | while read sink_input
	do
		pactl move-sink-input $sink_input $sink_output
	done

	echo "=> AFTER :"
	pactl list sink-inputs short
}

moveAudioToHDMI "$@"
