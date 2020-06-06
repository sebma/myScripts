#!/usr/bin/env bash
scriptBaseName=${0/*\/}
function create_Wi-Fi_From_QR_Code {
	if [ $# != 1 ];then
		echo "=> Usage: $scriptBaseName qrcodePictureFile" >&2
		return 1
	fi
	local qrcodePictureFile="$1"
	local qrdecode="zbarimg -q --raw"
	local ssid security pass hidden
	read ssid security pass hidden <<< $($qrdecode "$qrcodePictureFile" | awk -F":|;" '/WIFI:/{print$3" "$5" "$7" "$9}')
	[ $hidden = true ] && hidden=yes || hidden=no
	readonly ssid security pass hidden
	set -x
	nmcli device wifi connect $ssid password "$pass" name ${ssid}_TEST hidden $hidden
	set +x
}

create_Wi-Fi_From_QR_Code "$@"
