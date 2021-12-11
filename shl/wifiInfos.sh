#!/usr/bin/env bash

getprop 2>/dev/null | grep -q ro.build.version.release && export osFamily=Android || export osFamily=$(uname -s)
wifiInfos ()
{
	export LANG=C
	local physicalDevice wiFiDevice
	if [ $osFamily = Darwin ]; then
		echo "=> Darwin/macOS operating systems are not supported yet." 1>&2
		return 1
	fi
	wiFiDevice=$(iw dev 2>/dev/null | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')
	test "$wiFiDevice" || wiFiDevice="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { lastInterface=$2 } else { lastInterface=$1 } }END{print lastInterface}')"
	[ "$wiFiDevice" ] || {
		echo "=> ERROR : Could not find any wireless network card." 1>&2
		return 1
	}
	if which iw > /dev/null; then
		physicalDevice=$(iw dev | \sed -n "1s/#//;1p")
		echo "=> Wifi physical device capabilities :"
		iw phy $physicalDevice info
		echo "=> Stations infos. :"
		iw dev $wiFiDevice station dump
		echo "=> Wifi networks list :"
		which nmcli && nmcli dev wifi list || iw dev $wiFiDevice scan || \sudo iw dev $wiFiDevice scan
		echo "=> Connected network link status :"
		iw dev $wiFiDevice link || \sudo iw dev $wiFiDevice link
	fi
	which iwlist > /dev/null && {
		echo "========================================================================"
		iwlist $wiFiDevice bitrate || \sudo iwlist $wiFiDevice bitrate
		iwlist $wiFiDevice encryption || \sudo iwlist $wiFiDevice encryption
		iwlist $wiFiDevice frequency
		iwlist $wiFiDevice event
		iwlist $wiFiDevice retry
		iwlist $wiFiDevice scan | more
	}
}

wifiInfos
