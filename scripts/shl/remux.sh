#!/usr/bin/env bash

inputFile="$1"
if [ $# != 2 ]
then
	echo "=> Usage: $(basename $0) inputFileName outputFileName" >&2
	exit 1
fi

shift
extension=$(echo $1 | awk -F. '{print$NF}')

case $extension in
vob) options="-f mpeg" ;;
*) options="" ;;
esac

time ffmpeg -hide_banner -probesize 400M -analyzeduration 400M -i "$inputFile" -map 0 -c copy -c:d copy $options "$@"
