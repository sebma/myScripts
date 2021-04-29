#!/usr/bin/env bash

mediaStreamFormats="\\.(m3u|m3u8)"
tv2vieURL=http://www.tv2vie.org/television.html
#tv2vieStreamUrl=http://cdnhd2.oraolive.com:1935/tvstream/ngrp:tv2vieURL_all/playlist.m3u8
#tv2vieStreamUrl=http://cdnhd.oraolive.com:8081/tv2vieURL/tv2vieURL/playlist.m3u8
#tv2vieStreamUrl=http://pacific1471.serverprofi24.com:1935/tv2vieURL/tv2vieURL/playlist.m3u8
#tv2vieStreamUrl=http://cdnhd.oraolive.com:8081/tv2vieURL/abr/playlist.m3u8

tv2vieStreamUrl=$(curl -L -A Mozilla -# $tv2vieURL | perl -ne "
	s/^.*http:/http:/;
	s/$mediaStreamFormats([^\"]*).*$/.\$1\$2/i;
	print if /(http|ftp):.*$mediaStreamFormats/i;
")

echo "=> tv2vieStreamUrl = <$tv2vieStreamUrl>"

tmpFile=$(mktemp)
curl -# -L -m 10 -o $tmpFile "$tv2vieStreamUrl"
if [ $(grep -v ^# $tmpFile | wc -c) = 0 ]
then
	echo "=> ERROR: TV2Vie is not available at the moment." >&2
	read
else
	echo "=> tv2vieStreamUrl = <$tv2vieStreamUrl>"
	cat $tmpFile
	sleep 1
	nohup mpv --no-resume-playback --no-ytdl --vid=2 --aid=2 "$tv2vieStreamUrl" > /tmp/tv2vie_$USER.log 2>&1 &
fi
rm $tmpFile
