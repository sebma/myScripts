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
	local ffmpeg="$(which ffmpeg) -hide_banner"
	local metadataURL=description
	which AtomicParsley >/dev/null 2>&1 && local embedThumbnail="--embed-thumbnail" || local embedThumbnail="--write-thumbnail"

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
			ytdlExtraOptions="--hls-prefer-native"
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
#			*.facebook.com/*) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
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
				time LANG=C.UTF-8 command youtube-dl -o "$fileName" -f "${formats[$j]}" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail
				downloadOK=$?
				test $downloadOK != 0 && {
					time LANG=C.UTF-8 command youtube-dl -o $fileName -f "${formats[$j]}" "$url" 2>&1 | {
						egrep --color=auto -A1 'ERROR:.*' 1>&2
						echo 1>&2
						downloadOK=1
						return 1
					}
					downloadOK=$?
				}
			else
				time LANG=C.UTF-8 command youtube-dl -o $fileName -f "${formats[$j]}" "${ytdlExtraOptions[@]}" "$url" 2>&1 | {
					egrep --color=auto -A1 'ERROR:.*' 1>&2
					echo 1>&2
					downloadOK=1
					return 1
				}
				downloadOK=$?
			fi

			if [ $downloadOK = 0 ]; then
				if [ $extension = mp4 ] || [ $extension = m4a ];then
					if ! which AtomicParsley >/dev/null 2>&1; then
						if [ -s "${fileName/.$extension/.jpg}" ];then
							echo
							echo "[ffmpeg] Adding thumbnail to '$fileName'"
							$ffmpeg -loglevel repeat+warning -i "$fileName" -i "${fileName/.$extension/.jpg}" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "${fileName/.$extension/_NEW.$extension}"
							[ $? = 0 ] && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "${fileName/.$extension/.jpg}"
						fi
					fi
				elif [ $extension = mp3 ];then
					$ffmpeg -loglevel repeat+warning -i "$fileName" -i "${fileName/.$extension/.jpg}" -map 0 -map 1 -c copy -map_metadata 0 "${fileName/.$extension/_NEW.$extension}"
					[ $? = 0 ] && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "${fileName/.$extension/.jpg}"
				elif [ $extension = webm ];then
# Complicated with the "METADATA_BLOCK_PICTURE" ogg according to https://superuser.com/a/706808/528454 and https://xiph.org/flac/format.html#metadata_block_picture use another tool instead
					echo "=> NOT IMPLEMENTED YET"
					rm "${fileName/.$extension/.jpg}"
				fi

				if [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] || [ $extension = webm ];then
					timestampFileRef=$(mktemp) && touch -r "$fileName" $timestampFileRef
					[ $extension = mp4 ] &&  metadataURL=description
					[ $extension = webm ] && metadataURL=PURL
					if which mp4tags >/dev/null 2>&1;then
						mp4tags -m "$url" "$fileName"
					else
						echo "[ffmpeg] Adding '$url' to '$fileName' metadata"
						$ffmpeg -loglevel repeat+warning -i "$fileName" -map 0 -c copy -metadata $metadataURL="$url" "${fileName/.$extension/_NEW.$extension}" && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName"
					fi
					touch -r $timestampFileRef "$fileName" && \rm $timestampFileRef
				fi
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

bestFormats="bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best[ext=webm]/best[ext=avi]/best[ext=mov]/best[ext=flv]"
function getRestrictedFilenamesBEST {
	getRestrictedFilenamesFORMAT "($bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFHD {
	local height=1080
	local other_Formats=fhd
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesHD {
	local height=720
	local other_Formats=hd/high
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesHQ {
	local height=576
	local other_Formats=hq/fsd/std/sd
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFSD {
	local height=480
	local other_Formats=fsd/std/sd
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesSD {
	local height=360
	local other_Formats=low/sd/std
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesLD {
	local height=240
	local other_Formats=ld/low
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesVLD {
	local height=144
	local other_Formats=vld/low
	local possibleFormats="bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}

$funcName $@
