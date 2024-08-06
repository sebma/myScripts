#!/usr/bin/env bash

set -o nounset

scriptName=$(basename $0)
function usage {
	cat <<-EOF >&2
Usage: $scriptName [STRING]...
  or:  $scriptName OPTION

	-d|--debug		be even more verbose
	-h|--help 		display this help and exit
	-f|--formats	format(s) of video(s) to download
	-p|--playlist	create M3U playlist
	-t|--timeout	timeout the recording by speficied value (150m by default)
	-v|--verbose	output version information and exit
	-y|--overwite	overwrite all downloaded/generated files
	--ffmpeg-i		ffmpeg information log level
	--ffmpeg-w		ffmpeg warning log level
	--ffmpeg-e		ffmpeg error log level
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

	TEMP=$($getopt -o 'df:hp:t:vy' --long 'debug,downloader:,ffmpeg-e,ffmpeg-i,ffmpeg-w,formats:,help,playlist:,overwrite,timeout:,verbose,yt-dl,ytdl-k,ytdl-x,ytdl-v' -- "$@")

	if [ $? -ne 0 ]; then
		echo 'Terminating...' >&2
		exit 1
	fi

	# Note the quotes around "$TEMP": they are essential!
	eval set -- "$TEMP"

	while true; do
		case "$1" in
			-d|--debug) shift
				debug="set -x"
				ytdlInitialOptions+=( -v )
				let nbOptions++
				;;
			--downloader) shift
				downloader=$1
				shift
				let nbOptions+=2
				;;
			--ffmpeg-e) shift
				ffmpegLogLevel=repeat+error
				let nbOptions++
				;;
			--ffmpeg-i) shift
				ffmpegLogLevel=repeat+info
				let nbOptions++
				;;
			--ffmpeg-w) shift
				ffmpegLogLevel=repeat+warning
				let nbOptions++
				;;
			-f|--formats) shift
				formats=$1
				shift
				let nbOptions+=2
				;;
			-h|--help) shift
				usage=true
				let nbOptions++
				;;
			-p|--playlist) shift
				playlistFileName=$1
				shift
				let nbOptions+=2
				;;
			-t|--timeout) shift
				timeout=$1
				shift
				let nbOptions+=2
				;;
			-v|--verbose) shift
				let verboseLevel++
				let nbOptions++
				;;
			--yt-dl) shift
				downloader=youtube-dl
				let nbOptions++
				;;
			--ytdl-k) shift
				ytdlInitialOptions+=( -k )
				let nbOptions++
				;;
			--ytdl-x) shift
				ytdlInitialOptions+=( -x )
				let nbOptions++
				;;
			--ytdl-v) shift
				ytdlInitialOptions+=( -v )
				let nbOptions++
				;;
			-y|--overwrite) shift
				overwrite=true
				let nbOptions++
				;;
			-- ) shift; let nbOptions++; break ;;
			* ) break ;;
		esac
	done
#	lastArgs="$@"
	lastArgs=${@/*-- /}
}

nbOptions=0
usage=false
verboseLevel=0
debug="set +x"
formats=18
playlistFileName=unset
timeout=150m
downloader=yt-dlp
overwrite=false
ffmpegLogLevel=repeat+error

echo "=> @ = $@"
parseArgs "$@"
set | egrep "^(getopt|nbOptions|ffmpegLogLevel|verboseLevel|debug|formats|playlistFileName|timeout|downloader|overwrite|ytdlInitialOptions|TEMP)=" | sort
eval set -- "$lastArgs"
echo "=> @ = $@"

for arg in $@;do
	echo "-> arg = $arg"
done

[ $usage = true ] && usage
