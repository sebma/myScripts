#!/usr/bin/env bash

wifi5GHz() {
	wifiInterface=$(iw dev 2>/dev/null | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')
	test "$wifiInterface" || wifiInterface="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { lastInterface=$2 } else { lastInterface=$1 } }END{print lastInterface}')"
	if which iw >/dev/null 2>&1 ;then
		iw phy | egrep -q '5[0-9]{3} MHz' && echo true || echo false
	elif which iwlist >/dev/null 2>&1;then
		iwlist $wifiInterface frequency 2>&1 | grep "no frequency information" || iwlist $wifiInterface frequency | grep -q '5\..* GHz' && echo true || echo false
	fi
}

wifi5GHz
