#!/usr/bin/env bash

priereZoomHttps_URL="https://us04web.zoom.us/j/78356654717?pwd=bnFKSU5NTmRwVmxXZURaZlcrT1VLdz09"

zoommtgURL="$(echo "$priereZoomHttps_URL" | sed 's/^https:/zoommtg:/;s|/j/|/join?action=join\&confno=|;s/?pwd=/\&pwd=/')"
xdg-mime default Zoom.desktop x-scheme-handler/zoommtg
#xdg-mime query default x-scheme-handler/zoommtg
xdg-open $zoommtgURL

#echo "zoom $zoommtgURL & ..."
#zoom $zoommtgURL &
