#!/usr/bin/env bash

estimatedDuration=0m # last for ever when the "estimatedDuration" is unknown
format=94/231+233
case $# in
	1) url=$1;;
	2) estimatedDuration=$1; url=$2;;
	3) estimatedDuration=$1; format=$2; url=$3;;
	*) echo "=> Usage: ${0##*/} [ estimatedDuration=0m ] [ format=$format ] URL" >&2;exit 1;;
esac
#url="$(ytdlGetLiveURL.sh "$url")"
set -x
getRestrictedFilenamesFORMAT.sh --timeout $estimatedDuration -f $format $url
