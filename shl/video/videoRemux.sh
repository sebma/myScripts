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
 
 	test $# -ge 2 && local outputFilePath=$2 && shift 2 || local outputFilePath=.

  	local remainingArgs=("${@}")
#  	suffix=("${remainingArgs[@]/ /_}")
	suffix="${remainingArgs[@]}"
	suffix="${suffix/ /_}"
	outputFile="$outputFilePath/$fileBaseName-${suffix}-REMUXED.$extension"
 	outputExtension=${outputFile/*./}

	local options
	case $outputExtension in
		vob) options="-f mpeg" ;;
		*) options="" ;;
	esac

	local remuxOptions="-map 0 -c copy"
	local mp4Options="-movflags +frag_keyframe"
 	[ $extension = mp4 ] && remuxOptions="$remuxOptions $mp4Options"
	local ffmpeg="command  ffmpeg  -hide_banner"
	time $ffmpeg -i "$inputFile" $remuxOptions $options "${remainingArgs[@]}" "$outputFile"
	sync
	touch -r "$inputFile" "$outputFile"
 	echo "=> outputFile = <$outputFile>" >&2
}

videoRemux "$@"
