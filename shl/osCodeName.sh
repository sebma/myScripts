#!/usr/bin/env bash

distribName () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local osName=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	if [ $osFamily = Linux ]; then
		if type -P lsb_release >/dev/null 2>&1; then
			osName=$(lsb_release -si | awk '{print tolower($0)}')
			[ $osName = "n/a" ] && osName=$(source /etc/os-release && echo $ID)
		elif [ -s /etc/os-release ]; then
			osName=$(source /etc/os-release && echo $ID)
		fi
	elif [ $osFamily = Darwin ]; then
		osName="$(sw_vers -productName)"
	elif [ $osFamily = Android ]; then
		osName=Android
	elif [ $osFamily = VMkernel ]; then # ESXi
		osName=ESXi
  	else
		osName=$OSTYPE
	fi

	echo $osName | awk '{print tolower($0)}'
}

distribType () {
	local OSTYPE=$(bash -c 'echo $OSTYPE')
	local distribName=unknown
	local distribType=unknown
	echo $OSTYPE | grep -q android && local osFamily=Android || local osFamily=$(uname -s)

	distribName=$(distribName)

	if [ $osFamily = Linux ]; then
		case $distribName in
			sailfishos|rhel|fedora|centos) distribType=redhat ;;
			ubuntu) distribType=debian;;
			*) distribType=$distribName ;;
		esac
	elif [ $osFamily = Darwin ]; then
		distribType=Darwin
	elif [ $osFamily = Android ]; then
		distribType=Android
	elif [ $osFamily = VMkernel ]; then # ESXi
		distribType=ESXi
 	else
		type -P bash >/dev/null 2>&1 && distribType=$(bash -c 'echo $OSTYPE') || distribType=$osFamily
	fi

	echo $distribType
}
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
			if which lsb_release >/dev/null 2>&1;then
				osCodeName=$(lsb_release -sc)
			elif [ -f /etc/os-release ];then
				osCodeName=$(source /etc/os-release;echo $VERSION_CODENAME)
			else
				distribType=$(distribType)
				distribName=$(distribName)
				case $distribType in
					debian)
						;;
				esac
			fi
			;;
	esac
	echo $osCodeName
}
osCodeName
