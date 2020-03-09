#!/bin/bash

set -o nounset

tools="awk cut grep egrep sed head tail xargs tee sort strings"
if mount | grep -q "/usr "; then
	for tool in $tools;do declare $tool=$tool;done
else # Si /usr n'est pas monte, on utilise les applets busybox
	type busybox >/dev/null || exit
	for tool in $tools;do declare $tool="busybox $tool";done
fi

function systemType {
	local initPath=$(\ps -p 1 o cmd= | $cut -d" " -f1)
	$strings $initPath | $egrep -o "upstart|sysvinit|systemd" | $head -1
}
systemType
