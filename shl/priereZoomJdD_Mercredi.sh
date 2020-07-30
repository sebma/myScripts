#!/usr/bin/env sh

priereZoomHttps_URL="https://us04web.zoom.us/j/6378505229?pwd=d3RUR0hxQStIZGRSZEZMeEdveG5mdz09"

zoommtgURL="$(echo "$priereZoomHttps_URL" | sed 's/^https:/zoommtg:/;s|/j/|/join?action=join\&confno=|;s/?pwd=/\&pwd=/')"
xdg-mime default Zoom.desktop x-scheme-handler/zoommtg
#xdg-mime query default x-scheme-handler/zoommtg
xdg-open $zoommtgURL

#echo "zoom $zoommtgURL & ..."
#zoom $zoommtgURL &
