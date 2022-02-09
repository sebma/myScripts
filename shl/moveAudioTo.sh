#!/usr/bin/env bash

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}

function moveAudioTo {
	! pidof pulseaudio >/dev/null && echo "=> Pulseaudio is down, restarting Pulseaudio ..." && pulseaudio --start --log-target=syslog

	! pactl list sinks short >/dev/null 2>&1 && test "$SSH_CONNECTION" && pax11publish -r

	selectedOutputPattern="$1"
#	echo "=> selectedOutputPattern = $selectedOutputPattern"

	sink_output=$(pactl list sinks short | awk "/$selectedOutputPattern/"'{printf$1}')
	nbSinkInputs=$(pactl list sink-inputs short | wc -l)
	if [ $nbSinkInputs != 0 ] && [ -n "$sink_output" ] && ! pactl list sink-inputs short | egrep "^[0-9]+\s$sink_output\s" -q;then
		echo "=> ${0/*\/} ..."

		echo "=> BEFORE :"
		pactl list sink-inputs short

		echo "=> sink_output = <$sink_output>"
		pactl list sink-inputs short | awk '/protocol-native.c/{print$1}' | while read sink_input
		do
			pactl move-sink-input $sink_input $sink_output
		done

		echo "=> AFTER :"
		pactl list sink-inputs short

		echo "=> DONE."
	fi
}

moveAudio2AnalogStereo() { moveAudioTo '\.analog-stereo\>'; }
moveAudio2DigitalAudio() { moveAudioTo '\.iec958-stereo\>'; }
moveAudio2HDMI() { moveAudioTo '\.hdmi-stereo'; }

$funcName "$@"
