#!/usr/bin/env bash


[ $# -gt 1 ] && {
	echo "=> Usage: $0 [applicationPattern]"
	exit 1
}

typeset applicationPattern=$1
typeset answer=no

if [ -z "$applicationPattern" ];then
	read -p "Are you REALLY sure you want to delete all the DATA of ALL the applications ? (YES): " answer
fi

if [ -z "$applicationPattern" ]; then
	if [ -z "$answer" ] || [ $answer != YES ];then
		echo "=> INFO : Doing nothing, just exiting ..." >&2
		exit
	fi
fi

typeset adb=$(which adb)
typeset dos2unix="$(which tr) -d '\r'"

typeset packageList=$($adb shell pm list packages $applicationPattern | $dos2unix | cut -d: -f2)
#echo "=> packageList = <$packageList>"
for package in $packageList
do
	echo "=> Cleaning <$package> ..."
	$adb shell pm clear $package | $dos2unix
done
