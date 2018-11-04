#!/usr/bin/env bash

set -o | grep -q ^xtrace.*off && { declare -A | grep -wq colors || source $initDir/.colors; }
function getRestrictedFilenamesSD {
	trap 'rc=$?;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	youtube_dl=$(which youtube-dl)
	youtubeURLPrefix=https://www.youtube.com/watch?v=
	dailymotionURLPrefix=https://www.dailymotion.com/video/
	format="mp4"
	test $# != 0 && echo "=> There are $# urls to download ..."
	i=0
	for url in "$@"
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo "=> url = $url"
		echo "=> Testing if $url still exists ..."
		time LANG=C.UTF-8 $youtube_dl -f "$format" -qs -- "$url" 2>&1 | \grep --color=auto --color -A1 ^ERROR: && continue
		if ! echo $url | \egrep -wq "www"; then
			fileName=$(basename $( $locate -er "$url.*mp4$" | \egrep -v "\.part|AUDIO" | sort -rt. | head -1) 2>/dev/null)
			if ! test -w "$fileName"; then
				echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
				echo
				continue
			else
				if LANG=C.UTF-8 $youtube_dl -f "$format" -qs $youtubeURLPrefix$url 2> /dev/null; then
					url=$youtubeURLPrefix$url
				else
					if LANG=C.UTF-8 $youtube_dl -f "$format" -qs $dailymotionURLPrefix$url 2> /dev/null; then
						url=$dailymotionURLPrefix$url
					fi
				fi
			fi
		else
			echo $url | grep --color=auto -q youtube.com/ && urlSuffix="$(echo $url | cut -d= -f2 | sed 's/^-/\\&/')"
			if test "$urlSuffix" && fileName=$(basename $( $locate -er "$urlSuffix.*mp4$" | \egrep -v "\.part|AUDIO" | sort -rt. | head -1) 2>/dev/null) && test -s "$fileName"; then
				echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
				echo
				continue
			fi
		fi
#		set +x
		format="mp4[height<=?480]"
		echo
		fileName=$(LANG=C.UTF-8 $youtube_dl -f $format --get-filename --restrict-filenames -- "$url" || LANG=C.UTF-8 $youtube_dl -f $fallback --get-filename --restrict-filenames -- "$url")
		echo "=> fileName = <$fileName>"
		echo
		if [ -f "$fileName" ] && [ ! -w "$fileName" ]; then
			echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
			echo
			continue
		fi
		LANG=C.UTF-8 $youtube_dl -f $format "$url" --restrict-filenames && mp4tags -m "$url" "$fileName" && chmod -w "$fileName" && echo && $(which ffprobe) -hide_banner "$fileName"
		echo
	done
	sync
	trap - INT
}

getRestrictedFilenamesSD $@
