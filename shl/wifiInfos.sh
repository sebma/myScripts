#!/usr/bin/env sh

which iw >/dev/null && wiFiDevice=$(iw dev | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')
which iwconfig >/dev/null && wiFiDevice="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { print $2 } else { print $1 } }')"

[ "$wiFiDevice" ] || {
	echo "=> ERROR : Could not find any wireless network card." >&2
	exit 1
}

if which iw >/dev/null; then
	physicalDevice=$(iw dev | sed -n "1s/#//;1p")

	echo "=> Wifi physical device capabilities :"
	iw phy $physicalDevice info

	echo "=> Stations infos. :"
	iw dev $wiFiDevice station dump

	echo "=> Wifi networks list :"
	which nmcli && nmcli dev wifi list || sudo iw dev $wiFiDevice scan

	echo "=> Connected network link status :"
	sudo iw dev $wiFiDevice link
else
	which iwlist >/dev/null && {
		iwlist $wiFiDevice bitrate 
		iwlist $wiFiDevice frequency
		sudo iwlist $wiFiDevice encryption
		iwlist $wiFiDevice event
		iwlist $wiFiDevice retry
		iwlist $wiFiDevice scan | more
	}
fi
