#!/usr/bin/env bash

#set -o nounset
set -o errexit

if [ $# = 1 ]
then
	cdr_device=$1/VIDEO_TS
	dvd_mount=$1
else
	cdr_device=/dev/dvd
	dvd_mount=/media/dvd
fi

if ! test -e $cdr_device
then
	echo "=> ERROR : The directory $cdr_device does not exist." >&2
	exit 1
fi

#longestTrack=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//longest_track")
longestTrack=$(\lsdvd -Oy | awk -F ':|,| ' '/longest_track/{print$(NF-1)}')
#longestTrack=1
delta=$(tcprobe -i $cdr_device -T $longestTrack 2>&1 | awk -F' *|=|,' '/PTS/{printf$3"-"}END{print"0"}' | bc -l)
dvdTitleName=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//title")

if [ $dvdTitleName = unknown ]
then
	dvdTitleName=$1
fi

dvdxchap $cdr_device > "$dvdTitleName.chapters"

echo "=> DVD information :"
dvdInfo=$(tccat -i $cdr_device -T $longestTrack,-1 2>/dev/null | ffprobe -hide_banner - 2>&1)
echo "$dvdInfo"
isMono=$(echo $dvdInfo | egrep -q "Audio:.*mono" && echo true || echo false)
echo

ffmpegGeneralParams="-map 0"
ffmpegVideoParams="-vcodec libx264 -crf 30 -x264-params ref=4 -movflags frag_keyframe"
ffmpegSubtitleParams="-sn -metadata:s:s:0 language=fra"
ffmpegMetadataParams="-metadata:s:a:0 language=fra"

#ffmpegAudioParams="-acodec aac -aq 0.5 -ar 32k"
if $isMono
then
	ffmpegAudioParams="-acodec libfdk_aac -aprofile aac_he -vbr 1"
else
	ffmpegAudioParams="-acodec libfdk_aac -aprofile aac_he_v2 -vbr 1"
fi

if [ $delta != 0 ]
then
	set -x
	time tccat -i $cdr_device -T $longestTrack,-1 -d 2 | ffmpeg -hide_banner -i - -itsoffset $delta $ffmpegGeneralParams $ffmpegSubtitleParams $ffmpegAudioParams $ffmpegVideoParams $ffmpegMetadataParams "$dvdTitleName.mp4"
else
	set -x
	time tccat -i $cdr_device -T $longestTrack,-1 -d 2 | ffmpeg -hide_banner -i - $ffmpegGeneralParams $ffmpegSubtitleParams $ffmpegAudioParams $ffmpegVideoParams $ffmpegMetadataParams "$dvdTitleName.mp4"
fi

sync
set +x

#Si il y a des sous-titres
if lsdvd -s $cdr_device 2>/dev/null | grep -q Subtitle
then
	echo $cdr_device | grep -q ^/dev && pmount /dev/dvd
	tccat -i $cdr_device -T $longestTrack | tcextract -t vob -x ps1 -a 0x21 > francais.ps1
	time subtitle2vobsub -p francais.ps1 -i $dvd_mount/VIDEO_TS/VTS_01_0.IFO -a 0,fr -o francais
	sync
	echo $cdr_device | grep -q ^/dev && eject
fi

