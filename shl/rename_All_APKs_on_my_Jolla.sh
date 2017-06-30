#!/usr/bin/env bash

function rename_All_APKs {
	type aapt >/dev/null || return
	for package
	do
		echo "=> package = $package"
		[ -f "$package" ] || {
			echo "==> ERROR : The package $package does not exist." >&2; continue
		}

#		if echo $package | egrep -q "^[^\.]+\.apk"
#		if echo $package | egrep -q "^[^\.]+"
		if echo $package | grep -qP "^\w+$"
		then
			packagePath=$(dirname $package)
			packageID=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$2}')
			packageVersion=$(aapt dump badging "$package" | awk -F"'" '/^package:/{print$6}' | cut -d' ' -f1)
			packageNewFileName=$(echo "$packagePath/$packageID-$packageVersion.apk" | sed "s|^\./||;s|/|_|g")
			[ "$package" = $packageNewFileName ] || mv -v "$package" $packageNewFileName
		fi
	done
}

function main {
	cd
	type aapt >/dev/null || return
	jollaSDCardDir=~/jollaSDCard
	test -d $jollaSDCardDir || mkdir $jollaSDCardDir
	mount | grep -q $jollaSDCardDir || sshfs nemo@jolla-wlan:sdcard/ $jollaSDCardDir/ 
	for dir in $jollaSDCardDir/.aptoide/apks/ $jollaSDCardDir/Downloads/apk/
	do
		cd $dir && rename_All_APKs $(\ls *.apk); cd -
	done
	sync && fusermount -u $jollaSDCardDir
	jollaNemoHomeDir=~/jollaNemoHome
	test -d $jollaNemoHomeDir || mkdir $jollaNemoHomeDir
	mount | grep -q $jollaNemoHomeDir || sshfs nemo@jolla-wlan: $jollaNemoHomeDir/
	for dir in $jollaNemoHomeDir/android_storage/.aptoide/apks/ $jollaNemoHomeDir/android_storage/Download/apk/
	do
		cd $dir && rename_All_APKs $(\ls *.apk); cd -
	done
	sync && fusermount -u $jollaNemoHomeDir
}

main
