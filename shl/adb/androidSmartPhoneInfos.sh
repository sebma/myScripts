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

androidDeviceSerial=$($adb devices -l | awk -F ':| +' '/device /{print$(NF-2)}' | sort -u)

if [ $connectionOrIP_To_Connect = usb ];then 
	$adb disconnect
	androidDeviceNetworkInterface=$($adb shell ip addr | tr -s ' ' | egrep -v '(127.0.0.|169.254.0|inet6)' | grep -P '(\d+\.){3}\d+/\d+' | awk '{print$NF}')
	androidDeviceIP=$($adb shell ip addr show $androidDeviceNetworkInterface | tr -s ' ' | grep -w inet | cut -d' ' -f3 | cut -d/ -f1)
else
	$adb connect $connectionOrIP_To_Connect
	androidDeviceIP=$connectionOrIP_To_Connect
fi

set | grep androidDevice

if ! $adb shell echo; then
	retCode=$?
	echo
	$adb devices
	exit $retCode
fi

if [ -n "$androidDeviceSerial" ];then
	echo "=> INFO : You are connected to the $androidDeviceSerial android device via $connectionOrIP_To_Connect."
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
	uname >/dev/null 2>&1 && echo uname -m: && uname -m && echo uname -sr: && uname -sr
	echo
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
fi
