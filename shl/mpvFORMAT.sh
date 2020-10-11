#!/usr/bin/env bash

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}

unset -f mpvFORMAT
mpvFORMAT() {
	locat format="$1"
	local mpvConfigFile="$HOME/.config/mpv/mpv.conf"
	shift
	if grep -q "\[$format\]" "$mpvConfigFile";then
		mpv --profile="$format" "$@"
	else
		mpv --ytdl-format="$format" "$@"
	fi
}

mpvLD() { mpvFORMAT ld "$@"; }
mpvVLD() { mpvFORMAT vld "$@"; }
mpvSD() { mpvFORMAT sd "$@"; }
mpvFSD() { mpvFORMAT fsd "$@"; }
mpvHD() { mpvFORMAT hd "$@"; }
mpvFHD() { mpvFORMAT fhd "$@"; }
mpvBEST() { mpvFORMAT best "$@"; }

$funcName "$@"
