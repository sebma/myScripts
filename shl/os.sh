#!/usr/bin/env bash

osCodeName() {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osFamily=unknown
	local osCodeName=unknown
	local osx_major=-1
	local osx_minor=-1
	local OSX_MARKETING=()

	echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)
	case $osFamily in
		Darwin)
			osx_major=$(sw_vers -productVersion | cut -d. -f1)
			osx_minor=$(sw_vers -productVersion| awk -F '[.]' '{print $2}')
			if [ $osx_major -gt 10 ];then
#				echo "=> ERROR: This function supports only OS X/macOS versions 10.x." >&2
				osCodeName="$(awk '/SOFTWARE LICENSE AGREEMENT FOR /{gsub(/\\/,"");print$NF}' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf')"
				echo "$osCodeName"
				exit 1
			fi
			OSX_MARKETING=(
							[0]=Cheetah
							[1]=Puma
							[2]=Jaguar
							[3]=Panther
							[4]=Tiger
							[5]=Leopard
							[6]="Snow Leopard"
							[7]=Lion
							[8]="Mountain Lion"
							[9]=Mavericks
							[10]=Yosemite
							[11]="El Capitan"
							[12]=Sierra
							[13]="High Sierra"
							[14]=Mojave
							[15]=Catalina
						)
			osCodeName="${OSX_MARKETING[$osx_minor]}"
			;;
	esac
	echo $osCodeName
}

os() {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osFamily=unknown

	echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)
	case $osFamily in
		Darwin)
			if which sw_vers >/dev/null 2>&1;then
				echo $(sw_vers -productName) $(osCodeName) $(sw_vers -productVersion)
			elif which defaults >/dev/null 2>&1;then
				echo $(defaults read /System/Library/CoreServices/SystemVersion ProductName) $(osCodeName) $(defaults read /System/Library/CoreServices/SystemVersion ProductVersion)
			elif which system_profiler >/dev/null 2>&1;then
				system_profiler SPSoftwareDataType
			fi
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
