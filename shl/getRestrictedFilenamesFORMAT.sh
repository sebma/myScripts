#!/usr/bin/env bash

#set -o errexit
set -o nounset

LANG=C.UTF-8
scriptBaseName=${0/*\/}
scriptExtension=${0/*./}
scriptBaseName=${scriptBaseName/.$scriptExtension/}
funcName=$scriptBaseName
youtube_dl="command youtube-dl"

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=130;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	local initialSiteVideoFormat="$1"
	local siteVideoFormat downloadOK extension fqdn
	shift
	local -i i=0
	for url
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo
		echo "=> url = $url"
		echo $url | \egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url #Only youtube short urls are handled by "youtube-dl"
		fqdn=$(echo $url | awk -F "[./]" '{print$4"_"$5}')

		case $url in
		*.facebook.com/*) siteVideoFormat=\"$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g")\";; #Replace the first word after the oopening parenthesis
		*) siteVideoFormat=\"$initialSiteVideoFormat\";;
		esac

		echo
		echo "=> Downloading $url using the $siteVideoFormat format ..."
		echo

		echo "=> Testing if $url still exists ..."
		fileName=$(time $youtube_dl -f "$siteVideoFormat" --get-filename -- "$url" 2>&1)
		extension="${fileName/*./}"
		fileName="${fileName/.$extension/__$fqdn.$extension}"

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

		[ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] && $youtube_dl -o "$fileName" -f "$siteVideoFormat" "$url" --embed-thumbnail || $youtube_dl -o $fileName -f "$siteVideoFormat" "$url"
		downloadOK=$?
		if [ $downloadOK = 0 ] 
		then
			[ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] && mp4tags -m "$url" "$fileName"
			chmod -w "$fileName" && echo && videoInfo "$fileName"
		fi

		echo
	done
	sync
	trap - INT
}
function getRestrictedFilenamesBEST {
	getRestrictedFilenamesFORMAT "(best[ext=mp4]/best[ext=webm]/best[ext=flv])" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFHD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?1080]/mp4/best)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesHD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?720]/mp4/best)"  $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFSD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?480]/mp4/best)"  $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesSD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?360]/mp4/best)"  $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesLD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?240]/mp4/best)"  $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesVLD {
	getRestrictedFilenamesFORMAT "(mp4[height<=?144]/mp4/best)"  $@ # because of the "eval" statement in the "youtube_dl" bash variable
}

$funcName $@
