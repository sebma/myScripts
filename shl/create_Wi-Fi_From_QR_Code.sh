#!/usr/bin/env bash
scriptBaseName=${0/*\/}
function create_Wi-Fi_From_QR_Code {
	if [ $# != 1 ];then
		echo "=> Usage: $scriptBaseName qrcodePictureFile" >&2
		return 1
	fi
	local qrcodePictureFile="$1"
	if [ ! -s "$qrcodePictureFile" ];then
		echo "=> ERROR: The file <$qrcodePictureFile> does not exist or is empty." >&2
		return 2
	fi

	local qrdecode="zbarimg -q --raw"
	local ssid security pass hidden
	read ssid security pass hidden <<< $($qrdecode "$qrcodePictureFile" | awk -F":|;" '/WIFI:/{print$3" "$5" "$7" "$9}')
	[ $hidden = true ] && hidden=yes || hidden=no
	readonly ssid security pass hidden
#	local nmcliVersion=$(nmcli -v | awk -F"[. ]" '/version/{printf"%d.%d%02d\n", $4, $5, $6}')
	local nmcliVersion=$(nmcli -v | awk '/version/{print$NF}')
	if versionSmallerEqual $nmcliVersion 0.9.10;then
		echo "=>" nmcli device wifi connect $ssid password xxxxxxxxxxxx name ${ssid}_TEST
		nmcli device wifi connect $ssid password "$pass" name ${ssid}_TEST
	else
		echo "=>" nmcli device wifi connect $ssid password xxxxxxxxxxxx name ${ssid}_TEST hidden $hidden
		nmcli device wifi connect $ssid password "$pass" name ${ssid}_TEST hidden $hidden
	fi
}
function versionSmallerEqual {
	version1=$1
	version2=$2
	return $( perl -Mversion -e "exit ! ( version->parse( $version1 ) <= version->parse( $version2 ) )" )
}

create_Wi-Fi_From_QR_Code "$@"
