#!/usr/bin/env bash

function moveAudioToDigitalStereo {
	! pidof pulseaudio >/dev/null && echo "=> Pulseaudio is down, restarting Pulseaudio ..." && pulseaudio --start --log-target=syslog

	! pactl list sinks short >/dev/null 2>&1 && test "$SSH_CONNECTION" && pax11publish -r

	analogStereoOutputPattern='\.iec958-stereo\>'

	sink_output=$(pactl list sinks short | awk "/$analogStereoOutputPattern/"'{printf$1}')
	if [ -n "$sink_output" ] && ! pactl list sink-inputs short | egrep "^[0-9]+\s$sink_output\s" -q;then
		echo "=> BEFORE :"
		pactl list sink-inputs short

		echo "=> sink_output = $sink_output"
		pactl list sink-inputs short | awk '/protocol-native.c/{print$1}' | while read sink_input
		do
			pactl move-sink-input $sink_input $sink_output
		done

		echo "=> AFTER :"
		pactl list sink-inputs short
	fi
}

moveAudioToDigitalStereo "$@"
