#!/usr/bin/env bash

getRestrictedFilenamesSD () 
{ 
	youtube_dl=$(which youtube-dl)
	youtubeURLPrefix=https://www.youtube.com/watch?v=
	dailymotionURLPrefix=https://www.dailymotion.com/video/
	format="mp4"
	test $# != 0 && { 
		echo "=> There are $# urls to download ..."
	}
	i=0
	for url in "$@"
	do
		let i++
		echo "=> Downloading url #$i/$# ..."
		if echo $url | \egrep -vq "www"; then
			if LANG=C.UTF-8 $youtube_dl -qs $url 2> /dev/null; then
				:
			else
				if LANG=C.UTF-8 $youtube_dl -qs $youtubeURLPrefix$url 2> /dev/null; then
					url=$youtubeURLPrefix$url
				else
					if LANG=C.UTF-8 $youtube_dl -qs $dailymotionURLPrefix$url 2> /dev/null; then
						url=$dailymotionURLPrefix$url
					fi
				fi
			fi
		fi
		LANG=C.UTF-8 $youtube_dl -qs $url 2>&1 | grep --color ^ERROR: && continue
		format=$(LANG=C.UTF-8 $youtube_dl -F $url | egrep -vw "only|hls-[0-9]+"  | egrep '(webm|mp4|flv) .*([0-9]+x[0-9]+)|(unknown)' | egrep -wv "22|hd|http-720" | sort -k 2,2 -k 3,3rn | awk '{printf$1"/"}')
		echo "=> url = $url"
		echo
		fileName=$(LANG=C.UTF-8 $youtube_dl -f $format --get-filename "$url" --restrict-filenames || LANG=C.UTF-8 $youtube_dl -f $fallback --get-filename "$url" --restrict-filenames)
		echo "=> fileName = <$fileName>"
		echo
		if [ -f "$fileName" ] && [ ! -w "$fileName" ]; then
			echo "${color[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
			echo
			continue
		fi
		LANG=C.UTF-8 $youtube_dl -f $format "$url" --restrict-filenames && mp4tags -m "$url" "$fileName" && chmod -w "$fileName" && echo && $(which ffprobe) -hide_banner "$fileName"
		echo
	done
	sync
}

getRestrictedFilenamesSD $@
