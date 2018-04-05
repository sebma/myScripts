#!/usr/bin/env sh

set -x
#time -p avconv -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -map 0 -scodec copy -c:a copy -c:v copy -f vob output.vob
time -p  avconv -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -map 0 -c copy -f mpeg output.vob
sync
