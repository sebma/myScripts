#!/usr/bin/env bash

wifiList () {
	local wifiInterface=$(iw dev 2>/dev/null | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')
	type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo="command sudo" || sudo=""
	test "$wifiInterface" || wifiInterface="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { lastInterface=$2 } else { lastInterface=$1 } }END{print lastInterface}')"
	if [ -n "$wifiInterface" ]; then
		if type -P nmcli > /dev/null; then
			nmcliVersion=$(nmcli -v | awk -F"[. ]" '/version/{printf"%d.%d%02d\n", $4, $5, $6}')
			nmcli -f ssid,bssid,mode,freq,rate,signal,security,active dev wifi list | grep 'SSID' 1>&2
			nmcli -f ssid,bssid,mode,freq,rate,signal,security,active dev wifi list | grep -v 'SSID'
		else
			if type -P iw > /dev/null; then
				$sudo iw dev $wifiInterface scan | grep SSID
			else
				if type -P iwlist > /dev/null; then
					$sudo iwlist $wifiInterface scan | grep SSID
				fi
			fi
		fi
	fi
}

wifiList
