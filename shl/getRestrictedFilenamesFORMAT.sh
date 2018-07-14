#!/usr/bin/env bash

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT ()
{ 
	trap 'rc=$?;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	youtube_dl=$(which youtube-dl)
	youtubeURLPrefix=https://www.youtube.com/watch?v=
	dailymotionURLPrefix=https://www.dailymotion.com/video/
	test $# = 0 && { 
		echo "=> Usage: $FUNCNAME <format> url1 [url2] ..." 1>&2
		return 1
	}
	format="$1"
	shift
	test $# != 0 && { 
		echo "=> There are $# urls to download ..."
	}
	i=0
	for url in "$@"
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo "=> url = $url"
		fileNames=$($youtube_dl -f $format --get-filename "$url" --restrict-filenames || $youtube_dl -f $fallback --get-filename "$url" --restrict-filenames)
		for fileName in $fileNames
		do
			if ! echo $url | \egrep -wq "www"; then
				streamID=$url
				fileName=$(basename $( $locate -er "$streamID.*__${format}__" | \egrep -v "\.part|AUDIO" | sort -rt. | head -1) 2>/dev/null)
				if test -s "$fileName"; then
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
					echo
					continue
				else
					if $youtube_dl -f "$format" -qs $youtubeURLPrefix$url 2> /dev/null; then
						url=$youtubeURLPrefix$url
					else
						if $youtube_dl -f "$format" -qs $dailymotionURLPrefix$url 2> /dev/null; then
							url=$dailymotionURLPrefix$url
						fi
					fi
				fi
			else
				echo $url | grep --color=auto -q youtube.com/ && urlSuffix="$(echo $url | cut -d= -f2 | sed 's/^-/\\&/')"
				if test "$urlSuffix" && fileName=$(basename $( $locate -er "$urlSuffix.*__${format}__" | \egrep -v "\.part|AUDIO" | sort -rt. | head -1) 2>/dev/null) && test -s "$fileName"; then
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
					echo
					continue
				fi
			fi
			echo
			fileNames=$($youtube_dl -f $format --get-filename "$url" --restrict-filenames || $youtube_dl -f $fallback --get-filename "$url" --restrict-filenames)
			for fileName in $fileNames
			do
				echo "=> fileName = <$fileName>"
				echo
				if [ -f "$fileName" ] && [ ! -w "$fileName" ]; then
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
					echo
					continue
				fi
				$youtube_dl -f $format "$url" --restrict-filenames && mp4tags -m "$url" "$fileName" && chmod -w "$fileName" && echo && $(which ffprobe) -hide_banner "$fileName"
				echo
			done
		done
	done
	sync
	trap - INT
}

getRestrictedFilenamesFORMAT $@
