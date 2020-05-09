#!/usr/bin/env bash

if [ $# = 0 ];then
	echo "=> Usage : ${0/*\//} url1 url2 ..."
	exit 1
fi

getRestrictedFilenamesFORMAT.sh 249/139/250/140/251 "$@"
