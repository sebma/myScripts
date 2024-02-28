#!/usr/bin/env bash

function videoHFlip {
	local inputFile="$1"
	if [ $# != 2 ]
	then
		echo "=> Usage: $FUNCNAME inputFileName outputFileName [ffmpegCLIParameters]" >&2
		return 1
	fi

	shift
	outputFile="$1"
	outputExtension=${outputFile/*./}
	local options
	case $outputExtension in
		vob) options="-f mpeg" ;;
		*) options="" ;;
	esac

	mp4Options="-movflags +frag_keyframe"
	time $ffmpeg -i "$inputFile" $mp4Options -filter:v hflip -c:a copy $options "$@"
	sync
	touch -r "$inputFile" "$outputFile"
}

videoHFlip "$@"
