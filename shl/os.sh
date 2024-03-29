#!/usr/bin/env bash

os() {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osFamily=unknown

	echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)
	case $osFamily in
		Darwin)
			sw_vers > /dev/null 2>&1 && echo $(sw_vers -productName) $(sw_vers -productVersion) || system_profiler SPSoftwareDataType || defaults read /System/Library/CoreServices/SystemVersion ProductVersion
			;;
		Linux)
			if [ -s /etc/os-release ]; then
				( . /etc/os-release && echo $PRETTY_NAME )
			else
				if type -P lsb_release > /dev/null 2>&1; then
					\lsb_release -scd | paste -sd" "
					echo
				else
					\sed -n 's/\\[nl]//g;1p' /etc/issue
				fi
			fi
			;;
		*) ;;
	esac
}

os
