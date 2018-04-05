#!/usr/bin/env sh

#set -o nounset

cdr_device=$(ls -1 /dev/sr* | tail -1)

echo "$1" | egrep -q "^([0-9]+|all|\*)$" || {
	echo "=> Usage: <$0> <track number list separated by spaces>" >&2
	echo "=> Usage: <$0> <all | \"*\">" >&2
	exit 1
}

for tool in lsdvd tccat tcextract xmllint xmlstarlet
do
	type $tool >/dev/null || {
		echo "=> ERROR: <$tool> is not installed." >&2
		exit 2
	}
done

dvdRead=$(lsdvd -Ox $cdr_device 2>/dev/null)
test "$dvdRead" || {
	echo "=> ERROR: The DVD drive is not ready yet." >&2
	exit 3
}

#dvdTitleName=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//title")
dvdTitleName=$(blkid -o value -s LABEL /dev/dvd)
echo dvdTitleName = $dvdTitleName
longestTrack=$(lsdvd -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//longest_track")
echo longestTrack = $longestTrack
#audioFormat=$(lsdvd -t $longestTrack -a -Ox $cdr_device 2>/dev/null | xmlstarlet sel -t -v "//audio[1]/format")
#audioFormat=$(lsdvd -t $longestTrack -a -Ox $cdr_device 2>/dev/null | xmllint --xpath "//audio[1]/format/text()" -)
audioFormat=$(lsdvd -t $longestTrack -a -Ox $cdr_device 2>/dev/null | xmllint --xpath "//audio[1]/format/text()" - | sed 's/ $//;s/	*/ /g')
echo "audioFormat = <$audioFormat>"
totalChapters=$(lsdvd -t $longestTrack -c -Ox $cdr_device 2>/dev/null | grep -c /chapter)
echo totalChapters = $totalChapters

if [ "$1" = all ] || [ "$1" = "*" ]
then
	chapterList=$(seq -s " " $totalChapters)
	echo "=> Treating every chapters on the DVD."
else
	chapterList=$*
fi

case $audioFormat in
	ac3)
		for chapter in $chapterList
		do
			echo
			echo "==> Extracting track number $chapter ..."
			echo
			time -p tccat -i $cdr_device -T $longestTrack,$chapter | tcextract -t vob -x ac3 -a 0 > chapter_$chapter.ac3
		done
	;;
	lpcm)
		type ffmpeg >/dev/null || { echo "=> ERROR: <ffmpeg> is not installed." >&2 && exit 4; }
		ffmpeg() { $(which ffmpeg) "$@" 2>&1 | egrep -v "configuration:|^  lib|built on|Last message repeated|THIS PROGRAM IS DEPRECATED"; }
		for chapter in $chapterList
		do
			echo
			echo "==> Extracting track number $chapter ..."
			echo
			time -p tccat -i $cdr_device -T $longestTrack,$chapter | ffmpeg -i pipe: -vn chapter_$chapter.wav
		done
	;;
	mpeg1)
		for chapter in $chapterList
		do
			echo
			echo "==> Extracting track number $chapter ..."
			echo
			time -p tccat -i $cdr_device -T $longestTrack,$chapter | tcextract -t vob -x mp3 -a 0 > chapter_$chapter.mp2
		done
	;;
	*) echo "=> ERROR: The <$audioFormat> format is not supported." >&2; exit 5 ;;
esac

