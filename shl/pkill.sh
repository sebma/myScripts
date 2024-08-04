#!/usr/bin/env bash

function pkill {
	local firstArg=$1
	local pkill=/usr/bin/pkill
	local echoOption
	case $osFamily in
		Linux)
			echoOption="-e"
			;;
		Darwin)
			echoOption="-l"
			;;
		*)
			echoOption=""
			;;
	esac
	if [ $# != 0 ]; then
		firstArg="$1"
		if echo $firstArg | \egrep -q -- "-[0-9]|[A-Z]+"; then
			shift
			processName="$1"
			test -n "$processName" && $pkill $firstArg $echoOption -fu $USER "$@"
		else
			processName="$1"
			test -n "$processName" && $pkill $echoOption -fu $USER "$@"
		fi
	else
		$pkill
	fi
}

pkill "$@"
