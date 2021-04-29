#!/usr/bin/env bash

export LANG=fr_FR.iso88591
radio2vieURL=http://www.tv2vie.org/radio.html
#radio2vieStreamUrl=http://flux.radio2vie.org:8000/r2v
radio2vieStreamUrl=$(curl -LsA Mozilla $radio2vieURL | awk -F'"' '/mp3.*tp:/{print$(NF-1)}' | sort -u)
echo "=> radio2vieStreamUrl = <$radio2vieStreamUrl>"

if ! curl -m 10 -LsA Mozilla -i $radio2vieStreamUrl -r0-1 | egrep -q "HTTP/[0-9.]+ 200 "
then
	echo "=> ERROR: Radio2Vie is not available at the moment." >&2
	read
else
	sleep 1
	echo "=> Launching mpv ..."
	nohup mpv --no-resume-playback --no-ytdl --force-window=yes --geometry=50%:50% --autofit=50% "$radio2vieStreamUrl" > /tmp/radio2vie_$USER.log 2>&1 &
	sync
fi
