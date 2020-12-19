#!/usr/bin/env sh

os ()
{
	bash -c 'echo $OSTYPE' | grep -q android && local osFamily=Android || local osFamily=$(uname -s)
	case $osFamily in
		Darwin)
			sw_vers > /dev/null 2>&1 && echo $(sw_vers -productName) $(sw_vers -productVersion) || system_profiler SPSoftwareDataType || defaults read /System/Library/CoreServices/SystemVersion ProductVersion
			;;
		Linux)
			if [ -s /etc/os-release ]; then
				( . /etc/os-release && echo $PRETTY_NAME )
			else
				if which lsb_release > /dev/null 2>&1; then
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
