#!/usr/bin/env bash

ffmpeg="command ffmpeg -hide_banner"
time $ffmpeg -video_size $(xrandr | awk '/\*/{print$1}') -framerate 15 -f x11grab -i $DISPLAY.0
outFile=recordedScreenNoAudio.webp
#time $ffmpeg -video_size $(xrandr | awk '/\*/{print$1}') -framerate 15 -f x11grab -i $DISPLAY.0 $outFile
