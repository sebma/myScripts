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
        local distribName=""
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
	echo $normal
	local platform=$(uname -i)
	[ $platform = x86_64 ] && arch=amd64 || arch=i386
	LTSReleaseNumber=14.04
	LTSReleaseName=trusty
	tmpDir=/tmp/firefox-$(id -u)
	return
}
function main {
	initScript

	[ $# != 0 ] && firefoxPackageList=$@ || firefoxPackageList="firefox-locale-en firefox-globalmenu firefox firefox-locale-fr"
#	wgetFirefoxPackageList="${firefoxPackageList}_"
	wgetFirefoxPackageList="${firefoxPackageList}"
#	isAdmin && $sudo_cmd apt install -V -t $LTSReleaseName $firefoxPackageList && sync && exit
	baseUrl=http://uk.archive.ubuntu.com/ubuntu/pool/main/f/firefox/
	for package in $wgetFirefoxPackageList
	do
		echo "=> Downloading $package ..."
		wget -U "Mozilla/5.0" -nv -P $tmpDir/ -nd -nH -A "${package}_*$LTSReleaseNumber*$arch.deb" -rl1 $baseUrl
		ls -v $tmpDir/$package* >/dev/null || exit
		remoteVersion=$(ls -v $tmpDir/${package}_* | cut -d_ -f2 | tail -1)
		localVersion=$(dpkg-query --showformat='${Version}' -W $package | cut -d: -f2-)
		echo "=> remoteVersion = $remoteVersion"
		echo "=> localVersion  = $localVersion"
		[ "$remoteVersion" = $localVersion ] && break
	done
	[ "$remoteVersion" = $localVersion ] && rm -fr $tmpDir/ && exit

	mainPackage=firefox
	isAdmin && $sudo_cmd dpkg -i $tmpDir/${mainPackage}*$remoteVersion*$arch.deb
	set +x

#	for package in $firefoxPackageList
#	do
#		remoteVersion=$(ls $tmpDir/${package}_* | cut -d_ -f2)
#		localVersion=$(dpkg-query --showformat='${Version}' -W $package | cut -d: -f2-)
#		[ $remoteVersion != $localVersion ] && $sudo_cmd gdebi -n $tmpDir/${package}_*
#		rm $tmpDir/$package*
#	done
#	rmdir $tmpDir/
	rm -fr $tmpDir/
	sync

	return
}

main $@
