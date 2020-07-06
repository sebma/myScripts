#!/usr/bin/env sh

https2zoomtg () {
	if [ $# != 1 ]
	then
		echo "=> $(basename $0) httpsURL" >&2
	fi
	local httpsURL="$1"
	zoomtgURL=$(echo "$httpsURL" | sed "s/^https/zoomtg/;s|/j/|/join?action=join\&confno=|;s/?pwd=/\&pwd=/")
	echo "zoom $zoomtgURL"
	zoom $zoomtgURL &
}

https2zoomtg "$@"
