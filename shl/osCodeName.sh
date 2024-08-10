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
#				osCodeName="$(awk '/SOFTWARE LICENSE AGREEMENT FOR /{gsub(/\\/,"");print$NF}' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf')"
				OSX_MARKETING=(
						[11]="Big Sur"
						[12]=Monterey
						[13]=Ventura
						[14]=Sonoma
						[15]=Sequoia
						)
				osCodeName="${OSX_MARKETING[$osx_major]}"
			else
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
			fi
			;;
		Linux)
			if grep VERSION_CODENAME /etc/os-release -q 2>/dev/null;then
				osCodeName=$(source /etc/os-release;echo $VERSION_CODENAME)
			elif which lsb_release >/dev/null 2>&1;then
				osCodeName=$(lsb_release -sc)
			else
				distribType=$(distribType.sh)
				distribName=$(distribName.sh)
				case $distribType in
					debian)
						;;
					redhat)
						;;
				esac
			fi
			;;
	esac
	echo $osCodeName
}

osCodeName
