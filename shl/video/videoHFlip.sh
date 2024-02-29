#!/usr/bin/env bash

function videoHFlip {
	local inputFile="$1"
	if [ $# != 2 ]
	then
		echo "=> Usage: $FUNCNAME inputFileName [ outputFilePath | .] [ffmpegCLIParameters]" >&2
		return 1
	fi

	shift
	test $# -ge 2 && local outputFilePath=$2 || local outputFilePath=.
	outputFile="$outputFilePath/$fileBaseName-REMUXED.$extension"
	outputExtension=${outputFile/*./}
	local options
	case $outputExtension in
		vob) options="-f mpeg" ;;
		*) options="" ;;
	esac

	mp4Options="-movflags +frag_keyframe"
 	[ $extension = mp4 ] && options+=" $mp4Options"
	time $ffmpeg -i "$inputFile" $mp4Options -filter:v hflip -c:a copy $options "$@"
	sync
	touch -r "$inputFile" "$outputFile"
}

videoHFlip "$@"
