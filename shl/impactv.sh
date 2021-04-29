#!/usr/bin/env bash

mediaStreamFormats="\\.(m3u|m3u8)"
impactvUrl="http://livevideo.infomaniak.com/iframe.php?stream=impactv-live&name=impact_live&player=1933"
#impactvStreamUrl=http://livevideo.infomaniak.com/streaming/livecast/impactv-live/playlist.m3u8

impactvStreamUrl=$(curl -A Mozilla -# $impactvUrl | perl -ne "
        s/^.*http:/http:/;
        s/$mediaStreamFormats.*$/.\$1/i;
        print if /(http|ftp):.*$mediaStreamFormats/i;
")

impactvStreamUrl=$(echo $impactvStreamUrl | sed 's/"+a+"/impactv-live/')
#echo "=> impactvStreamUrl = <$impactvStreamUrl>"

tmpFile=$(mktemp)
curl -# -L -m 10 -o $tmpFile $impactvStreamUrl
if [ $(grep -v ^# $tmpFile | wc -c) = 0 ]
then
	echo "=> ERROR: ImpactTV is not available at the moment." >&2
	read
else
	echo "=> impactvStreamUrl = <$impactvStreamUrl>"
	cat $tmpFile
	sleep 1
	rm $tmpFile
#	nohup mpv --audio-channels=dl --volume=75 --softvol-max=300 --no-resume-playback --no-ytdl $impactvStreamUrl > /tmp/impactv_$USER.log 2>&1 &
	nohup mpv --audio-channels=dl --volume=75 --softvol-max=300 --no-resume-playback --no-ytdl $impactvStreamUrl 2>&1 | uniq | tee /tmp/impactv_$USER.log &
#	nohup vlc $impactvStreamUrl > /tmp/impactv_$USER.log 2>&1 &
#	nohup ffplay -hide_banner -ac 1 $impactvStreamUrl > /tmp/impactv_$USER.log 2>&1 &
	read
fi
