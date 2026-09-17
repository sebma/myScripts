#!/usr/bin/env bash

ffmpeg="command ffmpeg -hide_banner"
outFile=recordedWindowNoAudio.webp
time $ffmpeg -window_id $(xwininfo | awk '/Window id:/{printf$4}') -framerate 15 -f x11grab -i $DISPLAY.0 $outFile
