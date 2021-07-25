#!/usr/bin/env bash

[ $# = 0 ] || [ $1 = -h ] && {
	echo "=> Usage: ${0/*\//} m3uFile" 1>&2
	exit 1
}

tail -n +2 "$@" | tac | \sed -E 'N;s/\n#EXTINF:-1,/ # /' | tac
