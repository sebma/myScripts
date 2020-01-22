#!/usr/bin/awk -f

BEGIN {
	wifiScanCMD = "bash -c 'time sudo iw dev wlan0 scan'"
	while ( ( wifiScanCMD | getline ) > 0 ) {
		if( $1 == "BSS" ) {
			MAC = $2
			wifi[MAC]["enc"] = "Open"
		}
		if( $1 == "SSID:" ) {
		#	current_SSID = $2
		#	previous_SSID = wifi[MAC]["SSID"]
		#	previous_BSS = wifi[MAC]["BSS"]
		#	if( $2 ~ "\\x00") ) {
		#		if( previous_SSID == "" ) wifi[MAC]["SSID"] = "Hidden"
		#		else :
		#	} else if( $2 == "" ) ) {
		#	} else wifi[MAC]["SSID"] = $2
		
		#	if( $2 == "" && substr(wifi[MAC]["SSID"],0,1) == "" ) ) { wifi[MAC]["SSID"] = "Hidden" }
		#	else ) { if( substr($2, 0, 4) != "\\x00" ) wifi[MAC]["SSID"] = $2 }
			wifi[MAC]["SSID"] = $2
		}
		if( $1 == "freq:" ) {
			wifi[MAC]["freq"] = $NF " MHz"
		}
		if( $1 == "signal:" ) {
			wifi[MAC]["sig"] = $2 " " $3
		}
		if( $1 == "WPA:" ) {
			wifi[MAC]["enc"] = "WPA"
		}
		if( $1 == "WEP:" ) {
			wifi[MAC]["enc"] = "WEP"
		}
		if( /primary channel:/ ) {
			wifi[MAC]["channel"] = $4
		}
	}
	close(wifiScanCMD)

	printf "%s\t%s\t%s\t%s\t%s\t\t%s\n","BSSID","SSID","Channel","Frequency","Signal","Encryption"

	for (w in wifi) {
		printf "%s\t'%s'\t%s\t%s\t\t%s\t%s\n",w,wifi[w]["SSID"],wifi[w]["channel"],wifi[w]["freq"],wifi[w]["sig"],wifi[w]["enc"]
	}
}
