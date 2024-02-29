#!/usr/bin/env bash

function videoHFlip {
	local inputFile="$1"
	if [ $# = 0 ]
	then
		echo "=> Usage: $FUNCNAME inputFileName [ outputFilePath | .] [ffmpegCLIParameters]" >&2
		return 1
	fi

	extension=${inputFile/*./}
	fileBaseName=${inputFile%.???}
	shift

 	test $# -ge 1 && local outputFilePath=$1 && shift || local outputFilePath=.
	outputFile="$outputFilePath/$fileBaseName-FLIPPED.$extension"
	outputExtension=${outputFile/*./}
	local options
	case $outputExtension in
		vob) options="-f mpeg" ;;
		*) options="" ;;
	esac

	mp4Options="-movflags +frag_keyframe"
 	[ $extension = mp4 ] && options+=" $mp4Options"
	ffmpeg="command  ffmpeg  -hide_banner"
	time $ffmpeg -i "$inputFile" $mp4Options -filter:v hflip -c:a copy $options "$@" "$outputFile"
	sync
	touch -r "$inputFile" "$outputFile"
 	echo "=> outputFile = <$outputFile>"
}

videoHFlip "$@"
