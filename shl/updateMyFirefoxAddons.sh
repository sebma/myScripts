#!/usr/bin/env bash

set -o nounset
set -o errexit

function initColors {
        typeset escapeChar=$'\e'
        normal="$escapeChar[m"
        bold="$escapeChar[1m"
        blink="$escapeChar[5m"
        blue="$escapeChar[34m"
        cyan="$escapeChar[36m"

        yellowOnRed="$escapeChar[33;41m"

        greenOnBlue="$escapeChar[32;44m"
        yellowOnBlue="$escapeChar[33;44m"
        cyanOnBlue="$escapeChar[36;44m"
        whiteOnBlue="$escapeChar[37;44m"

        redOnGrey="$escapeChar[31;47m"
        blueOnGrey="$escapeChar[34;47m"
}

function isAdmin {
        local isLinux=$(uname -s | grep -q Linux && echo true || echo false)
	distribName=""
        if $isLinux
        then
                distribName=$(\ls -1 /etc/*release /etc/*version 2>/dev/null | awk -F"/|-|_" '!/system/ && NR==1 {print$3}')
                test $distribName = debian && distribName=$(awk -F= '/DISTRIB_ID/{print tolower($2)}' /etc/lsb-release)
        else
          distribName=Unix
        fi
        echo "=> distribName = $distribName"

        #set +o errexit
        local isAdmin=$(sudo -v && echo true || echo false)
        if $isAdmin
        then
                echo "=> Elevation de privileges reussie."
                sudo_cmd=sudo
        else
                echo "$yellowOnRed=> Echec d'elevation de privileges.$normal" >&2
                exit 1
                sudo_cmd=""
        fi
}

function initScript {
	initColors
	chmod u+x $0 || sudo chmod u+x $0
	LANG=C
	interpreter=`ps -o pid,comm | awk /$$/'{print $2}'`
	test $interpreter != bash && test $interpreter != bashdb && {
		echo "$yellowOnRed=> Mauvais interpreteur (interpreter = $interpreter), veuillez relancer le script $(basename $0) de la maniere suivante: ./$0$normal" >&2
		return 127
	}

	[ $BASH_VERSINFO != 4 ] && {
		echo "$blink$yellowOnRed=> ERROR: Bash version >= 4 is needed for hash value tables.$normal" >&2
		return 1
	}

	firefoxVersion=$(firefox -V 2>/dev/null | awk '{print$NF}' | tr -d [A-Za-z] | awk -F. '{print $1"."$2$3$4}')
	test $firefoxVersion || {
		echo "$blink$yellowOnRed=> ERROR: Firefox is not installed.$normal" >&2
		return 2
	}
	local maxFirefoxVersionSupported=-1


	isAdmin
	echo

	argc=$#
	case $distribName in
		centos|redhat|ubuntu)
			browser=firefox
#			test -d /usr/lib/$browser/extensions && adminExtensionDir=/usr/lib/$browser/extensions || adminExtensionDir=$(awk -F= '/LIBDIR=\//{print$2}' $(which $browser))/extensions
#			test -d $adminExtensionDir || adminExtensionDir=/usr/lib/$browser-addons/extensions
			;;
		debian)
			browser=iceweasel
			;;
		*) echo "$yellowOnRed=> <$distribName> is not supported by this script for the time being.$normal" >&2; return 3;;
	esac

	profilesIniPath=$HOME/.mozilla/firefox/profiles.ini
	[ $argc = 1 ] && profileName=$1 || profileName=$(awk -F= '/Profile0/{found=1} /Profile[^0]/{found=0} /Path=/ && found==1 {print$2}' $profilesIniPath)
	localExtensionDir=$HOME/.mozilla/firefox/$profileName/extensions
	test -d $localExtensionDir/.. && mkdir -p $localExtensionDir
	adminExtensionDir=/usr/lib/$browser/browser/extensions
	sleep 1
	pgrep -af $browser && echo "$yellowOnRed=> ERROR: You must stop $browser before running this script.$normal" >&2 exit 2

	echo "=> adminExtensionDir = $adminExtensionDir"
	echo "=> profileName = $profileName"
	echo "=> localExtensionDir = $localExtensionDir"
	cd $localExtensionDir
}

function main {
	initScript $@

	if cd $adminExtensionDir
	then
		extensionList="$(ls *.xpi | egrep -vi "langpack|messagingmenu|ss_ffao|textcomplete|03B08592-E5B4-45ff-A0BE-C1D975458688|5B280457-4290-40c2-9441-EA647775F824" | paste -sd" ")"
		echo "=> extensionList = $extensionList"
		echo
		for currentExtension in $extensionList
		do
			$sudo_cmd mv -v $currentExtension $localExtensionDir/
		done
		echo
		echo "=> Lancement de $browser avec le profil $profileName, lancer la mise a jour des modules ..."
		$browser -P $profileName >/dev/null
		set +o errexit
		for currentExtension in $extensionList
		do
			[ ! -f "$currentExtension" ] && continue
			$sudo_cmd mv -v $localExtensionDir/$currentExtension $adminExtensionDir/
		done
		$sudo_cmd chmod 644 $adminExtensionDir/*.xpi
	fi
}

main $@

