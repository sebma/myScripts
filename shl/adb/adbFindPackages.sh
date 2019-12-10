#!/usr/bin/env sh

adb=$(which adb)
[ $# != 1 ] && {
	echo "=> Usage: $0 applicationPattern"
	exit 1
}

applicationPattern=$1

$adb shell pm list packages -f -i "$applicationPattern"
