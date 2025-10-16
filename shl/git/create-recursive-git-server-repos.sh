#!/usr/bin/env bash

set -u

scriptBaseName=${0##*/}
if [ $# != 1 ];then
	echo "=> Usage: $scriptBaseName : depth" >&2
	exit 1
fi

depth=$1
find -maxdepth $depth -type d | while read dir;do
	if [ ! -d $dir/.git ];then
		cd $dir
		git init
		cd -
	fi
done
