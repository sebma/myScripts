#!/usr/bin/env bash

osType=$(uname -s)
if [ $osType = Linux ];then
	#getopt=$(getopt -V | grep getopt.*enhanced -q && getopt || getopts)
	if ! getopt -V | grep getopt.*util-linux -q && getopt=getopt;then
		echo "=> ERROR : You must use getopt from util-linux." >&2
		exit 2
	fi
elif [ $osType = Darwin ];then
	getopt=/usr/local/opt/gnu-getopt/bin/getopt
fi

TEMP=$($getopt -o 'dp:t:v' --long 'create-playlist:,debug,timeout:,verbose,yt-dlp,ytdl-k,ytdl-x,ytdl-v' -- "$@")

if [ $? -ne 0 ]; then
	echo 'Terminating...' >&2
	exit 1
fi

# Note the quotes around "$TEMP": they are essential!
eval set -- "$TEMP"
unset TEMP

debugLevel=0
while true; do
	case "$1" in
		-d|--debug) shift
			debugLevel=2
			debug="set -x" && ytdlInitialOptions+=( -v )
			;;
		-v|--verbose) shift
			debugLevel=1
			;;
		-p|--create-playlist) shift
			playlistFileName=$1
			shift
			;;
		-t|--timeout) shift
			estimatedDuration=$1
			shift
			;;
		--yt-dl) shift
			downloader=yt-dl
			;;
		--ytdl-k) shift
			ytdlInitialOptions+=( -k )
			;;
		--ytdl-x) shift
			ytdlInitialOptions+=( -x )
			;;
		--ytdl-v) shift
			ytdlInitialOptions+=( -v )
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done
