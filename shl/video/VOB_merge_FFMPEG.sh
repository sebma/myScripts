#!/usr/bin/env bash

set -x
#time -p ffmpeg -hide_banner -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -map 0 -scodec copy -c:a copy -c:v copy -f vob output.vob
time -p  ffmpeg -hide_banner -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -map 0 -c copy -f mpeg output.vob
sync
