#!/usr/bin/env bash

function systemType {
	local initPath=$(\ps -p 1 o cmd= | cut -d" " -f1)
	strings $initPath | egrep -o "upstart|sysvinit|systemd" | head -1
}
systemType
