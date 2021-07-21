#!/usr/bin/env bash

function moveAudioToAnalogStereo {
	! pidof pulseaudio >/dev/null && echo "=> Pulseaudio is down, restarting Pulseaudio ..." && pulseaudio --start --log-target=syslog

	echo "=> BEFORE :"
	! pactl list sinks short >/dev/null 2>&1 && test "$SSH_CONNECTION" && pax11publish -r
	pactl list sink-inputs short

	analogStereoOutputPattern='\.analog-stereo\>'
	sink_output=$(pactl list sinks short | awk "/$analogStereoOutputPattern/"'{printf$1}')
	echo "=> sink_output = $sink_output"

	pactl list sink-inputs short | awk '/protocol-native.c/{print$1}' | while read sink_input
	do
		pactl move-sink-input $sink_input $sink_output
	done

	echo "=> AFTER :"
	pactl list sink-inputs short
}

moveAudioToAnalogStereo "$@"
