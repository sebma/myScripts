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

if [ $connectionOrIP_To_Connect = usb ];then 
	$adb disconnect
	echo
	androidDeviceNetworkInterface=$($adb shell ip -o addr | egrep -v '(127.0.0.|169.254.0|inet6|loopback)' | awk '/inet /{print$2}')
	test -n "$androidDeviceNetworkInterface" && androidDeviceIP=$($adb shell ip -o addr show $androidDeviceNetworkInterface | awk -F ' *|/' '/inet /{print$4}')
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

androidDeviceSerial=$($adb shell getprop ro.serialno | sed $'s/\r//')
if [ -n "$androidDeviceSerial" ];then
	echo "=> INFO : You are connected to the $androidDeviceSerial android device via $connectionOrIP_To_Connect."
	echo
	set | grep androidDevice
	echo

	$adb shell "
	COLUMNS=176
	alias grep='grep --color'
	alias egrep='grep -E'
	test -n '$androidDeviceIP' && echo '=> IP Address is : $androidDeviceIP' && echo
	set | grep 'VERSION=' && echo
	printenv | grep HOSTNAME && echo
	grep --version
	echo
	uname >/dev/null 2>&1 && echo -n uname -m: && uname -m && echo -n uname -sr: && uname -sr && echo
	getprop | egrep 'ro.build.version.release|ro.build.version.sdk'
	echo
	getprop | egrep 'model|manufacturer|hardware|platform|revision|serialno|product.name|product.device|brand'
	echo
	dumpsys battery | egrep 'Current Battery|level|scale'
	echo
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
fi 2>&1 | sed $'s/\r//' | tee ${androidDeviceSerial}_$connectionOrIP_To_Connect.log

