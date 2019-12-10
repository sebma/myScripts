#!/usr/bin/env bash

adb=$(which adb)
connectionOrIP_To_Connect=usb

if [ $# != 0 ] && [ $# != 1 ]; then
	echo "=> Usage : $0 [usb] | IP@" >&2
	exit 1
fi

test -n "$1" && connectionOrIP_To_Connect=$1

if [ $connectionOrIP_To_Connect != usb ] && ! echo $connectionOrIP_To_Connect | grep -qP '(\d+\.){3}\d+'; then
	echo "=> ERROR[$0] : The must argument must either be \"usb\" or an ip address." >&2
	exit 2
fi

dos2unix="$(which tr) -d '\r'"
if [ $connectionOrIP_To_Connect = usb ];then 
	$adb disconnect
	echo
	androidDeviceNetworkInterface=$($adb shell getprop wifi.interface | $dos2unix)
	test -n "$androidDeviceNetworkInterface" && androidDeviceIP=$($adb shell ip -o addr show $androidDeviceNetworkInterface | awk -F ' *|/' '/inet /{print$4}' | $dos2unix)
	test -z "$androidDeviceNetworkInterface" && unset androidDeviceNetworkInterface
else
	$adb connect $connectionOrIP_To_Connect
	sleep 1
	androidDeviceIP=$connectionOrIP_To_Connect
fi

if ! $adb shell echo >/dev/null; then
	retCode=$?
	echo
	$adb devices
	exit $retCode
fi

androidDeviceSerial=$($adb shell getprop ro.serialno | $dos2unix)
androidCodeName=$($adb shell getprop ro.product.device | $dos2unix)
if [ -n "$androidDeviceSerial" ];then
	echo "=> INFO : You are connected to the $androidDeviceSerial android device via $connectionOrIP_To_Connect."
	echo
	set | grep ^android.*=
	echo

	test -n "$androidDeviceIP" && echo "=> IP Address is : $androidDeviceIP" && echo
	$adb shell "
	COLUMNS=176
	echo KSH_VERSION=\$KSH_VERSION
	echo
	echo HOSTNAME=\$HOSTNAME
	echo && grep --version 2>/dev/null && echo
	uname >/dev/null 2>&1 && echo -n 'uname -m: ' && uname -m && echo -n 'uname -sr: ' && uname -sr && echo
	type toolbox busybox toybox
"

	echo
	$adb shell getprop | egrep -w 'ro.build.version.release|ro.build.version.sdk|ro.product.device';echo
	$adb shell getprop | egrep 'model|manufacturer|hardware|platform|revision|serialno|product.name|product.device|brand|cpu.abi2|cpu.abi\>|wifi.interface|service.adb';echo
	$adb shell dumpsys battery | egrep 'Current Battery|level|scale';echo

	$adb shell "
	df -h 2>/dev/null || df
	echo
	wm size
	echo
	dumpsys cpuinfo | head -25 2>/dev/null || dumpsys cpuinfo
	echo
	dumpsys meminfo | head -25 2>/dev/null || dumpsys meminfo
	echo
	dumpsys processinfo | head -25 2>/dev/null || dumpsys processinfo
	echo
	head /proc/meminfo 2>/dev/null || cat /proc/meminfo
	echo
	tail /proc/cpuinfo 2>/dev/null || cat /proc/cpuinfo
	echo
"
else
	echo "=> $0: ERROR : No adb device detected." >&2
	exit 1
#fi | less -F
fi 2>&1 | $dos2unix | tee ${androidCodeName}_${androidDeviceSerial}_${connectionOrIP_To_Connect}.log

