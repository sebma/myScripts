#!/usr/bin/env bash

findLoopsInAllFS() {
	type sudo >/dev/null 2>&1 && [ $UID != 0 ] && sudo=$(which sudo) || sudo=""
	fsRegExp="ext[234]|btrfs"
	if $sudo true; then
		time for dir in $(df -T | awk "/$fsRegExp/"'{print$NF}' | egrep -vw "/home|/tmp") ;do sudo $(which find) $dir -xdev -follow -printf "";done
	fi
}

findLoopsInAllFS
