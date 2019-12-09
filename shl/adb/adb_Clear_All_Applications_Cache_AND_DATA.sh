#!/usr/bin/env bash


[ $# -gt 1 ] && {
	echo "=> Usage: $0 [applicationPattern]"
	exit 1
}

declare applicationPattern=$1
declare answer=no

if [ -z "$applicationPattern" ];then
	read -p "Are you REALLY sure you want to delete all the DATA of ALL the applications ? (YES): " answer
fi

if [ -z "$applicationPattern" ] && ( [ -z "$answer" ] || [ $answer != YES ] );then
	echo "=> INFO : Doing nothing, just exiting ..." >&2
	exit
fi

declare adb=$(which adb)
declare dos2unix="$(which tr) -d '\r'"

declare machingPackagesNumber=$($adb shell pm list packages $applicationPattern | $dos2unix | wc -l)
declare packageList=$($adb shell pm list packages $applicationPattern | $dos2unix | cut -d: -f2)
#echo "=> packageList = <$packageList>"
declare -i remainingPackages=$machingPackagesNumber
time for package in $packageList
do
	echo "=> Cleaning <$package> #$remainingPackages/$machingPackagesNumber remaining packages to process ..."
	$adb shell pm clear $package | $dos2unix
	let remainingPackages--
done
