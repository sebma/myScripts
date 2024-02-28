#!/usr/bin/env bash

function videoRemux {
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

	remuxOptions="-map 0 -c copy"
	mp4Options="-movflags +frag_keyframe"
	time $ffmpeg -i "$inputFile" $remuxOptions $mp4Options $options "$@"
	sync
	touch -r "$inputFile" "$outputFile"
}

videoRemux "$@"
