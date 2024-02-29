#!/usr/bin/env bash

function videoRemux {
	local inputFile="$1"
	if [ $# = 0 ]
	then
		echo "=> Usage: $FUNCNAME inputFileName [ outputFilePath | .] [ffmpegCLIParameters]" >&2
		return 1
	fi

	extension=${inputFile/*./}
	fileBaseName=${inputFile%.???}
 
 	test $# -ge 2 && local outputFilePath=$2 && shift || local outputFilePath=.
	outputFile="$outputFilePath/$fileBaseName-REMUXED.$extension"
	outputExtension=${outputFile/*./}
	local options
	case $outputExtension in
		vob) options="-f mpeg" ;;
		*) options="" ;;
	esac

	remuxOptions="-map 0 -c copy"
	mp4Options="-movflags +frag_keyframe"
 	[ $extension = mp4 ] && remuxOptions="$remuxOptions $mp4Options"
	ffmpeg="command  ffmpeg  -hide_banner"
	time $ffmpeg -i "$inputFile" $remuxOptions $options "$@" "$outputFile"
	sync
	touch -r "$inputFile" "$outputFile"
 	echo "=> outputFile = <$outputFile>"
}

videoRemux "$@"
