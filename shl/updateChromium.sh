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
	sudo_cmd=sudo
	initColors
	echo $normal
	local platform=$(uname -i)
	[ $platform = x86_64 ] && arch=amd64 || arch=i386
	LTSReleaseNumber=14.04
	LTSReleaseName=trusty
	tmpDir=/tmp/chromium-$(id -u)
	return
}
function main {
	initScript

	[ $# != 0 ] && packageList=$@ || packageList="chromium-browser-l10n chromium-codecs-ffmpeg-extra chromium-browser"
#	wgetPackageList="${packageList}_"
	wgetPackageList="${packageList}"
#	isAdmin && $sudo_cmd apt install -V -t $LTSReleaseName $packageList && sync && exit
	baseUrl=http://uk.archive.ubuntu.com/ubuntu/pool/universe/c/chromium-browser/
	for package in $wgetPackageList
	do
		echo "=> Downloading $package ..."
		[ $package = chromium-browser-l10n ] && currentArch=all || currentArch=$arch
#set -x
		wget -U "Mozilla/5.0" -nv -P $tmpDir/ -nd -nH -A "${package}_*$LTSReleaseNumber*$currentArch.deb" -rl1 $baseUrl
set +x
		ls -v $tmpDir/$package* >/dev/null || exit
		remoteVersion=$(ls -v $tmpDir/${package}_* | cut -d_ -f2 | tail -1)
		localVersion=$(dpkg-query --showformat='${Version}' -W $package | cut -d: -f2-)
		echo "=> remoteVersion = $remoteVersion"
		echo "=> localVersion  = $localVersion"
		[ "$remoteVersion" = $localVersion ] && break
		echo
	done
	[ "$remoteVersion" = $localVersion ] && rm -fr $tmpDir/ && exit

	mainPackage=chromium
	echo "=> $sudo_cmd dpkg -i $tmpDir/${mainPackage}*$remoteVersion*.deb ..."
	isAdmin && $sudo_cmd dpkg -i $tmpDir/${mainPackage}*$remoteVersion*.deb

#	for package in $packageList
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
