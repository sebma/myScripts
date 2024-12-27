#!/usr/bin/env bash
set -u
declare {isDebian,isRedHat}Like=false

echo $OSTYPE | grep -q android && osFamily=Android || osFamily=$(uname -s)

if [ $osFamily == Linux ];then
	distribID=$(source /etc/os-release;echo $ID)
	majorNumber=$(source /etc/os-release;echo $VERSION_ID | cut -d. -f1)

	if   echo $distribID | egrep "centos|rhel|fedora" -q;then
		isRedHatLike=true
	elif echo $distribID | egrep "debian|ubuntu" -q;then
		isDebianLike=true
		if echo $distribID | egrep "ubuntu" -q;then
			isUbuntuLike=true
		fi
	fi
elif [ $osFamily == Darwin ];then
	$brew ls openjdk | grep openjdk/.*/bin/java -q || $brew install openjdk
	$brew info android-commandlinetools | grep android-commandlinetools/.*/bin/sdkmanager -q || $brew install android-commandlinetools
	yes | sdkmanager --licenses >/dev/null
	if ! which emulator;then
		sdkmanager --install emulator
		ANDROID_SDK_ROOT=/usr/local/share/android-commandlinetools
		PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
	fi
fi
