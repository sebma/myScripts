#!/usr/bin/env bash

# cf. https://github.com/mpv-player/mpv/issues/6617#issuecomment-480818264

URL=$1
cat <<-EOF
Playing: $URL
 (+) Video --vid=1 (*) (h264 634x360 30.000fps)
 (+) Audio --aid=1 (*) (aac 1ch 48000Hz)
AO: [pulse] 48000Hz mono 1ch float
VO: [gpu] 634x360 yuv420p"
EOF

trap 'echo -e "\n\n\nExiting... (Quit)";exit' INT

seconds=0
while [ $seconds != 60 ]
do
	printf '\rAV: 00:00:%02d / 00:56:50 (0%%) A-V:  0.000 Cache: 1767s+147MB' $seconds
	let seconds++
	sleep 1
done

trap - INT
