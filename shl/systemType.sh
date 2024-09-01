#!/bin/bash

set -o nounset

tools="awk cut grep egrep sed head tail xargs tee tr sort strings"
if [ -s /usr/bin/tee ]; then # Si "/usr" est accessible
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas accessible, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

function systemType {
	local ps=unset
	ps --help 2>&1 | $grep -q "error while loading shared libraries" && ps="busybox ps" || ps="command ps"
	local initName=$($ps -e -o comm= -o pid= | $grep "  *1$" | $cut -d" " -f1)
	if [ -n "$initName" ];then
		initPath=$(type -P $initName) #Needed for gentoo and maybe others
		$strings $initPath | $egrep -o "upstart|sysvinit|systemd|launchd" | $head -1
	else
		echo unknown
		exit 1
	fi
}

systemType
