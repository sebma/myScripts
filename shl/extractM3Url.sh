#!/usr/bin/env ksh

mediaStreamFormats="\\.(m3u|m3u8)"
baseUrl="$1"
test $baseUrl || exit
extractedStreamUrl=$(curl -A Mozilla -# $baseUrl | perl -ne "
        s/^.*http:/http:/;
        s/$mediaStreamFormats.*$/.\$1/i;
        print if /(http|ftp):.*$mediaStreamFormats/i;
")

echo "=> extractedStreamUrl = <$extractedStreamUrl>"

test $extractedStreamUrl || exit

tmpFile=$(mktemp)
curl -# -L -m 10 -o $tmpFile $extractedStreamUrl
if [ $(grep -v ^# $tmpFile | wc -c) = 0 ]
then
	echo "=> ERROR: The stream is not available at the moment." >&2
	read
else
	printf "=> cat $tmpFile : "
	cat $tmpFile
	echo
#	nohup mpv --softvol-max=400 --no-resume-playback --no-ytdl $extractedStreamUrl > /tmp/impactv_$USER.log 2>&1 &
fi
rm $tmpFile
