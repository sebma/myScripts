#!/usr/bin/env sh

wifiSpeed() {
	wifiInterface=$(iw dev 2>/dev/null | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')
	test "$wifiInterface" || wifiInterface="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { lastInterface=$2 } else { lastInterface=$1 } }END{print lastInterface}')"
	iwlist $wifiInterface bitrate
	iw dev $wifiInterface info
}

wifiSpeed
