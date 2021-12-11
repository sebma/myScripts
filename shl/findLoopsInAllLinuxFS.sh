#!/usr/bin/env bash

findLoopsInAllLinuxFS() {
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && sudo="command sudo" || sudo=""
	fsRegExp="ext[234]|btrfs|f2fs|xfs|jfs|reiserfs|nilfs"
	if $sudo true; then
		time for dir in $(df -T | egrep -v "/media/" | awk "/$fsRegExp/"'{print$NF}' | egrep -vw "/home|/tmp" | sort -u)
		do
			echo "=> Scanning $dir ..." >&2
			sudo $(which find) $dir -xdev -follow -printf ""
		done
	fi
}

findLoopsInAllLinuxFS
