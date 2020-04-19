#!/usr/bin/env bash

#set -o nounset

[ $BASH_VERSINFO -ge 4 ] && declare -A colors=( [red]=$(tput setaf 1) [green]=$(tput setaf 2) [blue]=$(tput setaf 4) [cyan]=$(tput setaf 6) [yellow]=$(tput setaf 11) [yellowOnRed]=$(tput setaf 11)$(tput setab 1) [greenOnBlue]=$(tput setaf 2)$(tput setab 4) [yellowOnBlue]=$(tput setaf 11)$(tput setab 4) [cyanOnBlue]=$(tput setaf 6)$(tput setab 4) [whiteOnBlue]=$(tput setaf 7)$(tput setab 4) [redOnGrey]=$(tput setaf 1)$(tput setab 7) [blueOnGrey]=$(tput setaf 4)$(tput setab 7) )

LANG=C.UTF-8
scriptBaseName=${0/*\/}
scriptExtension=${0/*./}
scriptBaseName=${scriptBaseName/.$scriptExtension/}
funcName=$scriptBaseName
youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=127;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	local ytdlExtraOptions
	local translate=cat
	local initialSiteVideoFormat="$1"
	local siteVideoFormat downloadOK=-1 extension fqdn fileSizeOnFS=0 remoteFileSize=0
	shift
	local -i i=0
	local isLIVE=false

	echo $initialSiteVideoFormat | grep -q "^9[0-9]" && isLIVE=true
	if [ $BASH_VERSINFO -ge 4 ];then
		if $isLIVE;then
			ytdlExtraOptions=( --external-downloader ffmpeg --external-downloader-args "-movflags frag_keyframe+empty_moov" )
		else
			ytdlExtraOptions=( --hls-prefer-native )
		fi
	else
		if $isLIVE;then
			ytdlExtraOptions="--external-downloader ffmpeg --external-downloader-args -movflags\\ frag_keyframe+empty_moov"
		else
			ytdlExtraOptions=--hls-prefer-native
		fi
	fi

	for url
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo
		echo $url | \egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url
		fqdn=$(echo $url | awk -F "[./]" '{gsub("www.","");print$3"_"$4}')
		case $url in
			*.facebook.com/*)
				siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g")
			;;
			*)
				siteVideoFormat=$initialSiteVideoFormat
			;;
		esac
		echo "=> Testing if $url still exists ..."
		fileNames=$(set +x;time command youtube-dl -f "$siteVideoFormat" --get-filename -o "%(title)s__%(format_id)s__%(id)s.%(ext)s" --restrict-filenames -- "$url" 2>&1)
		echo $fileNames | \egrep --color -A1 ERROR: && echo && continue
		local -i j=0
		declare -a formats=($(echo $siteVideoFormat | \sed "s/,/ /g"))
		for fileName in $fileNames
		do
			echo
			echo "=> Downloading $url using the <${formats[$j]}> format ..."
			echo
			extension="${fileName/*./}"
			chosenFormatID=$(echo "$fileName" | awk -F '__' '{print$2}')
			fileName="${fileName/.$extension/__$fqdn.$extension}"
			if [ -f "$fileName" ] && [ $isLIVE = false ]; then
				echo "=> The file <$fileName> is already exists, comparing it's size with the remote file ..." 1>&2
				echo
				fileSizeOnFS=$(stat -c %s "$fileName")
				time remoteFileSize=$(command youtube-dl --ignore-config -j -f $chosenFormatID $url | jq -r .filesize)
				test $? != 0 && return
				[ $remoteFileSize = null ] && remoteFileSize=-1
				if [ ! -w "$fileName" ] || [ $fileSizeOnFS -ge $remoteFileSize ]; then
					echo
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded, skipping ...$normal" 1>&2
					echo
					let j++
					continue
				fi
			fi
			echo "=> fileName to be downloaded = <$fileName>"
			echo
			echo "=> chosenFormatID = $chosenFormatID"
			echo
			trap - INT
			if [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ]; then
				time LANG=C.UTF-8 command youtube-dl -o "$fileName" -f "${formats[$j]}" "${ytdlExtraOptions[@]}" "$url" --embed-thumbnail
				downloadOK=$?
				test $downloadOK != 0 && {
					time LANG=C.UTF-8 command youtube-dl -o $fileName -f "${formats[$j]}" "$url" 2>&1 | {
						egrep --color=auto -A1 'ERROR:.*No space left on device' 1>&2
						echo 1>&2
						downloadOK=1
						return 1
					}
					downloadOK=$?
				}
			else
				time LANG=C.UTF-8 command youtube-dl -o $fileName -f "${formats[$j]}" "${ytdlExtraOptions[@]}" "$url" 2>&1 | {
					egrep --color=auto -A1 'ERROR:.*No space left on device' 1>&2
					echo 1>&2
					downloadOK=1
					return 1
				}
				downloadOK=$?
			fi
			if [ $downloadOK = 0 ]; then
				[ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] && timestamp=$(mktemp) && touch -r "$fileName" $timestamp && mp4tags -m "$url" "$fileName" && touch -r $timestamp "$fileName" && \rm $timestamp
				chmod -w "$fileName"
				echo
				videoInfo.sh "$fileName"
			fi
			let j++
		done
	done
	echo
	sync
	set +x
	return $downloadOK
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
