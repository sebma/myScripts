#!/usr/bin/env bash

function mpvLog {
	local today=$(date +%Y%m%d)
	local mpv="command mpv";
	local mpvOptions="$mpvDefaultOptions --log-file=$HOME/log/mpv-$today.log";
	local DISPLAY=$DISPLAY;
	test "$SSH_CONNECTION" && hostname | \egrep -qi "b206$|eb1501p$" && export DISPLAY=:0;
	LANG=en_US.utf8 $mpv $mpvOptions "$@"
}

mpvLog "$@"
