#!/usr/bin/env sh

wifi5GHz() {
	if which iw >/dev/null 2>&1 ;then
		iw phy | egrep -q '5[0-9]{3} MHz' && echo true || echo false
	elif which iwlist >/dev/null 2>&1;then
		iwlist $wifiInterface frequency 2>&1 | grep "no frequency information" || iwlist $wifiInterface frequency | grep -q '5\..* GHz' && echo true || echo false
	fi
}

wifi5GHz
