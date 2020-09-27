#!/usr/bin/env bash

estimatedDuration=0m # last for ever when the "estimatedDuration" is unknown
format=94
case $# in
	1) url=$1;;
	2) estimatedDuration=$1; url=$2;;
	3) estimatedDuration=$1; format=$2; url=$3;;
	*) echo "=> Usage: ${0##*/} [ estimatedDuration=0m ] [ format=94 ] URL" >&2;exit 1;;
esac
set -x
timeout -s SIGINT $estimatedDuration getRestrictedFilenamesFORMAT.sh $format $url
