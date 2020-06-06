#!/usr/bin/env bash
scriptBaseName=${0/*\/}
function create_Wi-Fi_From_QR_Code {
#	local wifiInterface="$(iwconfig 2>/dev/null | awk '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { lastInterface=$2 } else { lastInterface=$1 } }END{print lastInterface}')"
	local wifiInterface=$(iw dev 2>/dev/null | awk '/Interface/{lastInterface=$NF}END{print lastInterface}')

	if ! iwlist $wifiInterface frequency | grep -q '5\..* GHz' 2>/dev/null || ! iw phy | egrep -q "[*] 5[0-9]{3} MHz";then
		echo "=> WARNING: Your Wi-Fi cannot connect to 5GHz networks." >&2
	fi

	if [ $# != 1 ];then
		echo "=> Usage: $scriptBaseName qrcodePictureFile" >&2
		return 1
	fi
	local qrcodePictureFile="$1"
	if [ ! -s "$qrcodePictureFile" ];then
		echo "=> ERROR: The file <$qrcodePictureFile> does not exist or is empty." >&2
		return 2
	fi

	local qrdecode=$(which zbarimg)
	if [ -z "$qrdecode" ];then
		echo "=> ERROR: You must install the <zbarimg> utility." >&2
		return 3
	fi

	qrdecode+=" -q --raw"
	local nmcliVersion=$(nmcli -v | awk '/version/{print$NF}')
	local ssid security pass hidden

	read ssid security pass hidden <<< $($qrdecode "$qrcodePictureFile" | awk -F":|;" '/WIFI:/{print$3" "$5" "$7" "$9}')
	[ $hidden = true ] && hidden=yes || hidden=no
	readonly ssid security pass hidden

	if versionSmallerEqual $nmcliVersion 0.9.10;then
		echo "=>" nmcli device wifi connect $ssid password xxxxxxxxxxxx name ${ssid}
		nmcli device wifi connect $ssid password "$pass" name ${ssid}
	else
		echo "=>" nmcli device wifi connect $ssid password xxxxxxxxxxxx name ${ssid} hidden $hidden
		nmcli device wifi connect $ssid password "$pass" name ${ssid} hidden $hidden
	fi
}
function versionSmallerEqual {
	version1=$1
	version2=$2
	return $( perl -Mversion -e "exit ! ( version->parse( $version1 ) <= version->parse( $version2 ) )" )
}

create_Wi-Fi_From_QR_Code "$@"
