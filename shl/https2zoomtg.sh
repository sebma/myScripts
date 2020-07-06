#!/usr/bin/env sh

https2zoomtg () {
	if [ $# != 1 ]
	then
		echo "=> Usage: $(basename $0) httpsURL" >&2
		return 1
	fi

	zoommtgURL="$(echo "$1" | sed 's/^https:/zoommtg:/;s|/j/|/join?action=join\&confno=|;s/?pwd=/\&pwd=/')"
	echo "zoom $zoommtgURL & ..."
	zoom $zoommtgURL &
}

https2zoomtg "$@"
