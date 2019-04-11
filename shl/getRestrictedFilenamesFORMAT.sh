#!/usr/bin/env bash

[ $BASH_VERSINFO -ge 4 ] && export declare="declare -A" || export declare="declare"
$declare colors
[ $BASH_VERSINFO -ge 4 ] && colors=( [red]=$(tput setaf 1) [green]=$(tput setaf 2) [blue]=$(tput setaf 4) [cyan]=$(tput setaf 6) [yellow]=$(tput setaf 11) [yellowOnRed]=$(tput setaf 11)$(tput setab 1) [greenOnBlue]=$(tput setaf 2)$(tput setab 4) [yellowOnBlue]=$(tput setaf 11)$(tput setab 4) [cyanOnBlue]=$(tput setaf 6)$(tput setab 4) [whiteOnBlue]=$(tput setaf 7)$(tput setab 4) [redOnGrey]=$(tput setaf 1)$(tput setab 7) [blueOnGrey]=$(tput setaf 4)$(tput setab 7) )

LANG=C.UTF-8
scriptBaseName=${0/*\/}
scriptExtension=${0/*./}
scriptBaseName=${scriptBaseName/.$scriptExtension/}
funcName=$scriptBaseName
youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command

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
		echo $fileName | \egrep --color -A1 ERROR: && echo && continue
		extension="${fileName/*./}"
		fileName="${fileName/.$extension/__$fqdn.$extension}"

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
