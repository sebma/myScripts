#!/usr/bin/env bash

case $1 in
	-h|-help|--h|--help|-*|"") echo "=> Usage: $0 [applicationPattern|-h|AlL]" >&2; exit 1 ;;
esac

declare applicationPattern=$1
if [ "$applicationPattern" = AlL ];then
	declare answer=no
	read -p "Are you REALLY sure you want to delete all the DATA of ALL the applications ? (YeS): " answer
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

declare matchingPackagesNumber=$($adb shell pm list packages | \egrep "$applicationPattern" | $dos2unix | wc -l)
declare packageList=$($adb shell pm list packages | \egrep "$applicationPattern" | $dos2unix | cut -d: -f2)
declare -i remainingPackages=$matchingPackagesNumber

#time for package in $packageList
time $adb shell pm list packages $applicationPattern | $dos2unix | cut -d: -f2 | while read package
do
	echo "=> Cleaning <$package> $remainingPackages/$matchingPackagesNumber remaining packages to process ..."
	echo $adb shell pm clear $package
	$adb shell pm clear $package
	sleep 1
	let remainingPackages--
done | $dos2unix
