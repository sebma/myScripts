#!/usr/bin/env bash

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}

unset -f mpvFORMAT
mpvFORMAT() {
	local mpv="$(which mpv 2>/dev/null)"
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)
	[ $osFamily = Linux ] && [ -c /dev/fb0 ] && tty | egrep -q "/dev/tty[0-9]+" && local mpvDefaultOptions="--vo=drm" && local mplayerDefaultOptions="--vo=fbdev2"
	mpv="$mpv $mpvDefaultOptions"
	local mpvConfigFile="$HOME/.config/mpv/mpv.conf"
	local format="$1"
	shift

	# Si on lance mpv via un ssh sur le PC b206, alors on ne forward pas l'affichage
	if [ "$SSH_CONNECTION" ];then
		hostname | grep -qi b206$ && DISPLAY=:0 
	fi

	if grep -q "\[$format\]" "$mpvConfigFile";then
		LANG=en_US.utf8 nohup $mpv --profile="$format" "$@" &
	else
		LANG=en_US.utf8 nohup $mpv --ytdl-format="$format" "$@" &
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
