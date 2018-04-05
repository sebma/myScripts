#!/usr/bin/env sh

#set -o nounset

cdr_device=$(ls -1 /dev/sr* | tail -1)

test $1 && [ $1 = "-h" ] && {
	echo "=> Usage $0 [startingChapter]"
	exit 1
}

longestTrack=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//longest_track")
#echo "=> longestTrack = $longestTrack"
set -o nounset
#dvdTitleName=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//title")
dvdTitleName=$(blkid -o value -s LABEL /dev/dvd)
#echo "=> dvdTitleName = $dvdTitleName"

dvdxchap -t $longestTrack $cdr_device > $dvdTitleName.chap.txt
chmod -w $dvdTitleName.chap.txt
if test $1
then
	startingChapter=$1
	time -p mplayer dvd://$longestTrack --chapter=$startingChapter- --dumpstream --dumpfile=$dvdTitleName.vob && eject $cdr_device
else
	time -p mplayer dvd://$longestTrack --dumpstream --dumpfile=$dvdTitleName.vob && eject $cdr_device
fi 
echo "=> Dumped into <$dvdTitleName.vob>"
echo "=> Chapters list dumped into <$dvdTitleName.chap.txt>"
chmod -w $dvdTitleName.vob
