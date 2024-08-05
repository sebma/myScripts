#!/usr/bin/env bash

set -o nounset

scriptName=$(basename $0)
function usage {
	cat <<-EOF >&2
Usage: $scriptName [STRING]...
  or:  $scriptName OPTION

	-h|--help 		display this help and exit
	-v|--verbose	output version information and exit
	-y|--overwite	overwrite all downloaded/generated files
	-d|--debug		be even more verbose
	-p|--playlist	create M3U playlist
	-t|--timeout	timeout the recording by speficied value (150m by default)
	--yt-dl			change downloader to "youtube-dl" (default is "yt-dlp")
	--ytdl-k		keep downloaded intermediate files
	--ytdl-x		extract audio
	--ytdl-v		set downloader in verbose mode

EOF
	exit 1
}

function parseArgs {
	osType=$(uname -s)
	if [ $osType = Linux ];then
		if getopt -V | grep getopt.*util-linux -q;then
			export getopt=getopt
		else
			echo "=> ERROR : You must use getopt from util-linux." >&2
			exit 2
		fi
	elif [ $osType = Darwin ];then
		export getopt=/usr/local/opt/gnu-getopt/bin/getopt
	fi

	TEMP=$($getopt -o 'dhp:t:vy' --long 'playlist:,debug,help,overwrite,timeout:,verbose,yt-dl,ytdl-k,ytdl-x,ytdl-v' -- "$@")

	if [ $? -ne 0 ]; then
		echo 'Terminating...' >&2
		exit 1
	fi

	# Note the quotes around "$TEMP": they are essential!
	eval set -- "$TEMP"
	unset TEMP

	while true; do
		case "$1" in
			-d|--debug) shift
				debug="set -x"
				ytdlInitialOptions+=( -v )
				;;
			-h|--help) shift
				usage=true
				;;
			-v|--verbose) shift
				verboseLevel+=1
				;;
			-p|--playlist) shift
				playlistFileName=$1
				shift
				;;
			-t|--timeout) shift
				estimatedDuration=$1
				shift
				;;
			--yt-dl) shift
				downloader=youtube-dl
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
			-y|--overwrite) shift
				overwrite=true
				;;
			-- ) shift; break ;;
			* ) break ;;
		esac
	done
	[ $usage = true ] && usage
}

usage=false
declare -i verboseLevel=0
#debug="set +x"
#playlistFileName=unset
#estimatedDuration=150m
#downloader=yt-dlp
#overwrite=false
parseArgs "$@"
set | egrep "^(getopt|verboseLevel|debug|playlistFileName|estimatedDuration|downloader|overwrite|ytdlInitialOptions)=" | sort
