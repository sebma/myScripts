#!/usr/bin/env bash

trap 'echo "=> SIGINT Received, exiting";exit' INT

test $(id -u) != 0 && mkdir -p $HOME/.local/share/applications

cdda2mp3() {
	musicDir=$(ls -d ~/Musique ~/Music 2>/dev/null)
	sourceDir="$(ls -d $(mount | awk '/gvfs/{print$3}')/*cdda* 2>/dev/null)"

	test "$sourceDir" || {
		echo "<$0> Error: The CDDA is not mounted." >&2
		exit 1
	}

	totalTracksNumber=$(ls -1 "$sourceDir" | wc -l)
	if [ "$1" = all ] || [ "$1" = "*" ]
	then
		trackNumberList=$(seq -s " " $totalTracksNumber)
		echo "=> Treating all tracks on the CD."
	else
		trackNumberList=$*
	fi
	echo

	for trackNumber in $trackNumberList
	do
		file="Track $trackNumber.wav"
		echo "=> Treating <$file> ..."
		outputFile="$(basename "$file" .wav).mp3"
		test -f "$musicDir/$outputFile" && echo "=> Already treated this one." || {
			echo "=> Copying <$sourceDir/$file> in /tmp ..."
			rsync -Pt -pv "$sourceDir/$file" /tmp || { echo "=> Interrupted, treating next file ..."; continue; }
			echo "=> Encoding </tmp/$file> to <$musicDir/$outputFile> ..."
			lame -V2 --replaygain-accurate "/tmp/$file" "$musicDir/$outputFile"
			echo "=> Done."
		}
	done
	echo

	echo "=> The files are in <$musicDir> :"
	ls -lh $musicDir/Track*.mp3
}

cdtext2mp3id3() {
	set -o nounset

	musicDir=$(ls -d ~/Musique ~/Music 2>/dev/null)
	sourceDir="$(ls -d $(mount | awk '/gvfs/{print$3}')/*cdda* 2>/dev/null)"

	test "$sourceDir" || {
		echo "<$0> Error: The CDDA is not mounted." >&2
		exit 1
	}

	CD_INFO=$(icedax -L1 -gJH -v toc 2>&1)

	cdtext_encoding=$(echo "$CD_INFO" | file -bi - | cut -d= -f2)
	standard_encoding=utf8
	echo "=> cdtext_encoding = $cdtext_encoding"
#	CD_INFO=$(echo "$CD_INFO" | iconv -f $cdtext_encoding -t $standard_encoding)
	CD_INFO=$(echo "$CD_INFO" | iconv -t $standard_encoding)
	echo

	totalTracksNumber=$(echo "$CD_INFO" | awk -F":| " '/^Tracks:/{print$2}')
	if [ "$1" = all ] || [ "$1" = "*" ]
	then
		trackNumberList=$(seq -s " " $totalTracksNumber)
		echo "=> Treating all tracks on the CD."
	else
		trackNumberList=$*
	fi
	echo

#	isCDText=$(echo "$CD_INFO" | grep -q "CD-Text: detected" && echo true || echo false)
	if $isCDText
	then
		artist=$(echo "$CD_INFO" | awk -F"'" '/Album title:/{print$(NF-1)}')
		artist=$(echo $artist | tr '[\\]' '[_]')
		test "$artist" && albumDir="$musicDir/$artist" || albumDir="$musicDir/UNKNOWN"
		album=$(echo "$CD_INFO" | awk -F"'" '/Album title:/{print$2}')
		album=$(echo $album | tr '[\\]' '[_]')
		test "$album" && albumDir="$albumDir - $album" || albumDir="$albumDir - UNKNOWN"

		mkdir -p "$albumDir"

		echo "=> album = <$album>"
		echo "=> albumDir = <$albumDir>"
		echo "=> artist = <$artist>"
#set -x
		for trackNumber in $trackNumberList
		do
			echo
			file="Track $trackNumber.wav"
			echo "=> Treating <$file> ..."
			trackTitle=$(echo "$CD_INFO" | awk -F"' | '" "/^$(printf 'T%02d: ' $trackNumber)/"'{print$2}')
			trackTitle=$(echo $trackTitle | sed 's/ $//;s/\\//g;s/		*/ /g;')
			trackTitle=$(echo $trackTitle | tr '[/]' '[\-]')
			echo "==> trackTitle = <$trackTitle>"
			echo
#			outputFile="$(basename "$file" .wav).mp3"
			outputFile="$artist - $trackTitle - $(printf %02d $trackNumber).mp3"
			test -f "$albumDir/$artist - $trackTitle - $(printf %02d $trackNumber).mp3" && echo "=> Already treated this one." || {
				echo "==> Copying <$sourceDir/$file> in /tmp ..."
				rsync -Pt -pv "$sourceDir/$file" /tmp || { echo "=> Interrupted, treating next file ..."; continue; }
				echo "==> Encoding </tmp/$file> to <$albumDir/$outputFile> ..."
				echo "==> trackTitle = <$trackTitle>"
				lame -V2 --replaygain-accurate --id3v2-utf16 --add-id3v2 --tl "$album" --ta "$artist" --tt "$trackTitle" --tn "$trackNumber/$totalTracksNumber" "/tmp/$file" "$albumDir/$outputFile"
				mv -v "$albumDir/$outputFile" "$albumDir/$artist - $trackTitle - $(printf %02d $trackNumber).mp3"
				echo "=> Done."
			}
		done
		echo

#		id3ren -template="$musicDir/%a - %s.mp3" $albumDir/*.mp3
		echo "=> The files are in <$albumDir> :"
		ls -lh "$albumDir/"*.mp3
		echo
		id3 -l "$albumDir/"*.mp3

		if [ "$1" = all ] || [ "$1" = "*" ]
		then
			echo
			echo "=> The full encoding of <$artist - $album> is finished, ejecting CD..."
			eject $CDDA_DEVICE && echo "=> Done."
		fi
	fi
}

main() {
#	audioMimeTypes="$(mimetype -b .wav .wma .aac .ac3 .mp2 .mp3 .ogg .oga .m4a .mid | grep audio | sort | xargs) audio/x-vorbis+ogg"
#	xdg-mime default audacious.desktop $audioMimeTypes

	type lame >/dev/null 2>&1 || {
		echo "=> Installing: lame ..."
		sudo apt-get install -yqq lame id3 id3v2
	}
	rc=$?
	type lame >/dev/null || {
		echo "=> The tool <lame> could not be installed." >&2
		exit $rc
	}

	export CDR_DEVICE=$( ls -1 /dev/sr* | tail -1)
	export CDDA_DEVICE=$(ls -1 /dev/sr* | tail -1)

	test -z $CDR_DEVICE && {
		echo "=> ERROR: No CDR drive found." >&2
		exit 1
	}

	#isBigger=$(awk "BEGIN {if ($(lsb_release -sr)>=12.10) print \"true\"; else print \"false\";}")

	type icedax >/dev/null 2>&1 || {
		echo "=> Installing: icedax ..."
		sudo apt-get install -yqq icedax
	}
	rc=$?
	type icedax >/dev/null || {
		echo "=> The tool <icedax> could not be installed." >&2
		exit $rc
	}

	echo "$1" | egrep -q "^([0-9]+|all|\*)$" || {
		echo "=> Usage: <$0> <track number list separated by spaces>" >&2
		echo '=> Usage: <'$0'> <all | *>' >&2
		exit 1
	}

	echo "=> Scanning the Audio CD ..."
	blkid $CDR_DEVICE || {
		echo "=> ERROR: The drive is empty." >&2
#		exit 2
	}

	#gvfs-mount -l | awk '/cdda/{line=$NF}END{printf line}'
	gvfs-mount -l | grep -q $(basename $CDR_DEVICE) || gvfs-mount cdda://$(basename $CDR_DEVICE)
	echo
	cdrecord -atip 2>&1 >/dev/null | egrep --color "Cannot load media|No disk" && {
		echo "=> ERROR: The drive is empty." >&2
		exit 2
	}

	icedax -gJH -v toc 2>&1 | head -7
	echo

	cddaMountPoint="$(ls -d $(mount | awk '/gvfs/{print$3}')/*cdda* 2>/dev/null)"
	test "$cddaMountPoint" || {
		echo "<$0> Error: The CDDA is not mounted." >&2
		echo Waiting 5s ...
		sleep 5
	}

	test "$cddaMountPoint" || cddaMountPoint="$(ls -d $(mount | awk '/gvfs/{print$3}')/*cdda* 2>/dev/null)"
	ls "$cddaMountPoint" >/dev/null 2>&1 || {
		echo Mount point OK, searching audio tracks ...
		echo Waiting 5s ...
		sleep 5
		ls "$cddaMountPoint" || exit
	}

	ls -lh "$cddaMountPoint/"*
	echo

#	isCDText=$(icedax -L1 -gJH -v toc 2>&1 | grep -q "CD-Text: detected" && echo true || echo false)
	isCDText=$(icedax -L1 -gJH -v toc 2>&1 | egrep -q "Album title: '[^']+'" && echo true || echo false)
	if $isCDText
	then
		echo "=> INFO: This Audio CD contains CD-Text information."
		cdtext2mp3id3 "$*"
	else
		echo "=> INFO: This Audio CD does not contain any CD-Text information."
		cdda2mp3 "$*"
	fi
}

main $@

