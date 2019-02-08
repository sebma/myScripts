#!/usr/bin/env bash

set -o | \grep -q ^xtrace.*off && { declare -A | \grep -wq colors || source $initDir/.colors; }
function getRestrictedFilenamesSD {
	trap 'rc=130;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	youtube_dl=$(which youtube-dl)
	youtube_dl_Format="mp4[height<=?480]"
	i=0
	for url
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo "=> url = $url"
		echo "=> Testing if $url still exists ..."
		fileName=$(time LANG=C.UTF-8 $youtube_dl -f "$youtube_dl_Format" --get-filename --restrict-filenames -- "$url" 2>&1)
		echo $fileName | \egrep --color -A1 ^ERROR: && echo && continue
		echo

		if [ -f "$fileName" ] && [ ! -w "$fileName" ]
		then
			echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" >&2
			echo
			continue
		fi

		echo "=> fileName to be downloaded = <$fileName>"
		echo

		echo $url | \egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url #Only youtube short urls are handled by "youtube-dl"
		LANG=C.UTF-8 $youtube_dl -f $youtube_dl_Format "$url" --restrict-filenames && mp4tags -m "$url" "$fileName" && chmod -w "$fileName" && echo && command ffprobe -hide_banner "$fileName"

		echo
	done
	sync
	trap - INT
}

debug=$1
[ "$debug" = "-x" ] && shift && set -x
getRestrictedFilenamesSD $@
