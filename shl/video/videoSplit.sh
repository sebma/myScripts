#!/usr/bin/env bash

function videoSplit {
	if [ $# != 2 ] && [ $# != 3 ] && [ $# != 4 ]
	then
		echo "=> Usage: $FUNCNAME <filename> hh:mm:ss[.xxx] [ hh:mm:ss[.xxx] ] [ outputFilePath | .]" >&2
		return 1
	fi

	fileName="$1"
	test -r "$fileName" || {
		echo "=> ERROR: <$fileName> cannot be read by $USER or does not exist." >&2
		return 2
	}

	extension=${fileName/*./}
	fileBaseName=${fileName%.???}
	begin=$2
	test $# = 4 && local outputFilePath=$4 || local outputFilePath=.
	outputFile="$outputFilePath/$fileBaseName-CUT.$extension"
	chmod -x "$fileName"

	remuxOptions="-map 0 -c copy"
	mp4Options="-movflags +frag_keyframe"
	[ $extension = mp4 ] && remuxOptions="$remuxOptions $mp4Options"
	ffmpeg="command  ffmpeg  -hide_banner"
	if test $# -ge 3
	then
		end=$3
#		duration=$(echo $(date +%s.%N -d $end) - $(date +%s.%N -d $begin) | bc -l)
#		time $ffmpeg -ss $begin -t $duration -i "$fileName" $remuxOptions "$outputFile"
		set -x
		time $ffmpeg -ss $begin -to $end -i "$fileName" $remuxOptions "$outputFile"
	else
		set -x
		time $ffmpeg -ss $begin -i "$fileName" $remuxOptions "$outputFile"
	fi
	set +x
	sync
	touch -r "$fileName" "$outputFile"
	echo "=> outputFile = <$outputFile>"
}

videoSplit "$@"
