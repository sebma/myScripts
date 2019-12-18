#!/usr/bin/env bash

case $1 in
	-h|-help|--h|--help|-*|"") echo "=> Usage: $0 [applicationPattern|-h|AlL]" >&2; exit 1 ;;
esac

declare applicationPattern=$1
if [ "$applicationPattern" = AlL ];then
	declare answer=no
	read -p "Are you REALLY sure you want to disable ALL USER applications ? (YeS): " answer
	if [ "$answer" = YeS ];then
		applicationPattern=.
	else
		echo "=> INFO : Doing nothing, just exiting ..." >&2
		exit
	fi
fi

adb get-state >/dev/null || exit

declare adb=$(which adb)
declare dos2unix="$(which tr) -d '\r'"

declare matchingPackagesNumber=$($adb shell pm list packages -3 | \egrep "$applicationPattern" | $dos2unix | wc -l)
declare packageList=$($adb shell pm list packages -3 | \egrep "$applicationPattern" | $dos2unix | cut -d: -f2)
#echo "=> packageList = <$packageList>"
declare -i remainingPackages=$matchingPackagesNumber
time for package in $packageList
do
	echo "=> Disabling <$package> #$remainingPackages/$matchingPackagesNumber remaining packages to process ..."
#	$adb shell pm disable $package || $adb shell pm disable-until-used $package || $adb shell pm disable-user $package
	let remainingPackages--
done | $dos2unix
