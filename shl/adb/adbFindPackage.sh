#!/usr/bin/env sh

[ $# != 1 ] && {
	echo "=> Usage: $0 applicationPattern"
	exit 1
}

applicationPattern=$1

adb shell pm list packages "$applicationPattern" | cut -d: -f2-
