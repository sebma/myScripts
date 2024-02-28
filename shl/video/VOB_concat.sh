#!/usr/bin/env bash

set -x
time -p pv $@ | ffmpeg -hide_banner -i - -probesize 400M -analyzeduration 400M -map 0 -c copy -f mpeg "${1/?.vob/_FULL.vob}"
sync
