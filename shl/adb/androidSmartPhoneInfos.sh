#!/usr/bin/env sh

adb devices -l
adb shell "
	alias grep='grep --color'
	alias egrep='grep -E'
	set | grep 'VERSION='
	echo
	printenv | grep HOSTNAME
	echo
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
" | less
