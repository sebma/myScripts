#!/bin/bash

function systemType {
	local cut="busybox cut"
	local head="busybox head"
	local strings="busybox strings"
	local initPath=$(\ps -p 1 o cmd= | $cut -d" " -f1)
	$strings $initPath | egrep -o "upstart|sysvinit|systemd" | $head -1
}
systemType
