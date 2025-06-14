#!/usr/bin/env bash

function processENV_Variables ()
{
	if [ $# != 1 ] && [ $# != 2 ]; then
		echo "=> Usage: $FUNCNAME processName [varNAME]" 1>&2
		return 1
	fi
	local processName=$1
	local -i pid=0
	pid=$(\pidof -s $processName)
	if [ $# = 1 ]; then
		[ $pid != 0 ] && tr '\0' '\n' < /proc/$pid/environ | \egrep -v "^hidden=" | \grep -P "^[^\s%]+=" | sort -u
	else
		if [ $# = 2 ]; then
			local varNAME=$2
			[ $pid != 0 ] && tr '\0' '\n' < /proc/$pid/environ | \egrep -v "^hidden=" | \grep -P "^[^\s%]+=" | sort -u | egrep --color "$varNAME"
		fi
	fi
}

processENV_Variables "$@"
