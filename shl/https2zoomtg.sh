#!/usr/bin/env sh

https2zoomtg () {
	if [ $# != 1 ]
	then
		echo "=> Usage: $(basename $0) httpsURL" >&2
		return 1
	fi

	zoommtgURL="$(echo "$1" | sed 's/^https:/zoommtg:/;s|/j/|/join?action=join\&confno=|;s/?pwd=/\&pwd=/')"
	xdg-mime default Zoom.desktop x-scheme-handler/zoommtg
#	xdg-mime query default x-scheme-handler/zoommtg
	xdg-open $zoommtgURL

#	echo "zoom $zoommtgURL & ..."
#	zoom $zoommtgURL &
}

https2zoomtg "$@"
