#!/usr/bin/env sh

getprop 2>/dev/null | grep -q ro.build.version.release && export osFamily=Android || export osFamily=$(uname -s)
wifiCapabilities ()
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
	physicalDevice=$(iw dev 2>/dev/null | \sed -n "1s/#//;1p")
	test "$physicalDevice" && echo "=> Wifi physical device capabilities :" && iw phy $physicalDevice info
	which iwlist > /dev/null && {
		echo "========================================================================"
		iwlist $wiFiDevice bitrate || \sudo iwlist $wiFiDevice bitrate
		iwlist $wiFiDevice encryption || \sudo iwlist $wiFiDevice encryption
		iwlist $wiFiDevice frequency
		iwlist $wiFiDevice event
		iwlist $wiFiDevice retry
	}
}

wifiCapabilities
