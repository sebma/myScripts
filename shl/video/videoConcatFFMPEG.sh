#!/usr/bin/env bash

set -o nounset

scriptName=$(basename $0)
function scriptHelp {
	cat <<-EOF >&2
=> Usage: $scriptName [option] destFile video1 video2 ...
	-h	display this help and exit
	-l	use lossless concatenation (with concat demuxer) this is the default
	-d	use ffmpeg concat demuxer
	-f	use ffmpeg concat filter
	-p	use ffmpeg concat protocol
EOF
	exit 1
}
function videoConcatFFMPEG_Losslessly-concat_demuxer {
	if [ $# -lt 3 ]; then
		echo "=> Usage: $FUNCNAME destFile video1 video2 ..." 1>&2
		return 1
	fi

	local destFile="$1"
	shift
	local videosListFile="$(mktemp -p .)"
	local indexOfFiles=-1

	for video in "$@"
	do
		extension="${video/*./}"
		echo "file '$video'" >> "$videosListFile"
		let indexOfFiles+=1
	done

	set -x
	time $ffmpeg -f concat -i "$videosListFile" -c copy $(printf -- "-map %d " {1..$indexOfFiles}) "$destFile"
	set +x
	\rm -i -vf "$videosListFile"
	sync
}
function videoConcatFFMPEG_WithLoss-concat_demuxer {
	if [ $# -lt 3 ]; then
		echo "=> Usage: $FUNCNAME destFile video1 video2 ..." 1>&2
		return 1
	fi

	local destFile="$1"
	shift
	local extension="${destFile/*./}"
	local videosListFile="$(mktemp -p .)"
	local indexOfFiles=-1
	[ $extension = mp4 ] && local mp4Options="-movflags +frag_keyframe"

	for video in "$@"
	do
		echo "file '$video'" >> "$videosListFile"
		let indexOfFiles+=1
	done

	set -x
	time $ffmpeg -f concat -i "$videosListFile" $(printf -- "-map %d " {1..$indexOfFiles}) $mp4Options "$destFile"
	set +x
	\rm -i -vf "$videosListFile"
	sync
}
function videoConcatFFMPEG_WithLoss-concat_filter {
	if [ $# -lt 3 ]; then
		echo "=> Usage: $FUNCNAME destFile video1 video2 ..." 1>&2
		return 1
	fi

	local destFile="$1"
	shift
	local extension="${destFile/*./}"
	local indexOfFiles=0
	local filter_complex=""
	[ $extension = mp4 ] && local mp4Options="-movflags +frag_keyframe"

	for video in "$@"
	do
		filter_complex+="[$indexOfFiles:v] [$indexOfFiles:a] "
		let indexOfFiles+=1
	done

	filter_complex+="concat=n=$indexOfFiles:v=1:a=1 [v] [a]"
	set -x
	time $ffmpeg $(printf -- "-i %s " "$@") -filter_complex "$filter_complex" -map "[v]" -map "[a]" $mp4Options "$destFile"
	set +x
	sync
}
function main {
	local OPTSTRING=hldfp
	while getopts $OPTSTRING NAME; do
		case "$NAME" in
			h|*) scriptHelp ;;
		esac
	done
	[ $OPTIND = 1 ] && scriptHelp
	shift $((OPTIND-1)) #non-option arguments

	return $codeRet
}

main "$@"
