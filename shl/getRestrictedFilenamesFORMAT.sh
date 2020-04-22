#!/usr/bin/env bash

#set -o nounset
[ $BASH_VERSINFO -lt 4 ] && echo "=> [WARNING] BASH_VERSINFO = $BASH_VERSINFO then continuing in bash4 ..." && exec bash4 $0 "$@"
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
	local ytdlExtraOptions="--add-metadata"
	local translate=cat
	local initialSiteVideoFormat="$1"
	local siteVideoFormat downloadOK=-1 extension fqdn fileSizeOnFS=0 remoteFileSize=0
	shift
	local -i i=0
	local isLIVE=false
	local ffmpeg="$(which ffmpeg) -hide_banner"
	local metadataURL=description
	local embedThumbnail="--write-thumbnail"
	local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__%(extractor)s.%(ext)s"
	local AtomicParsley=$(which AtomicParsley 2>/dev/null)

	echo $initialSiteVideoFormat | grep -q "^9[0-9]" && isLIVE=true

	if [ $BASH_VERSINFO -ge 4 ];then
		if $isLIVE;then
			ytdlExtraOptions+=( --external-downloader ffmpeg --external-downloader-args "-movflags frag_keyframe+empty_moov" )
		else
			ytdlExtraOptions+=( --hls-prefer-native )
		fi
	else
		if $isLIVE;then
			ytdlExtraOptions+=" --external-downloader ffmpeg --external-downloader-args -movflags\\ frag_keyframe+empty_moov"
		else
			ytdlExtraOptions+=" --hls-prefer-native"
		fi
	fi

	for url
	do
		let i++
		echo "=> Downloading url # $i/$# ..."
		echo
		echo $url | egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url
		urlBase=$(echo "$url" | cut -d/ -f1-3)
		fqdn=$(echo "$url" | cut -d/ -f3 | awk -F. '{print$(NF-1)"."$NF}')
		fqdnStringForFilename=$(echo $fqdn | tr . _)
		youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__$fqdnStringForFilename.%(ext)s"
		domain=$(echo $fqdn | awk -F '[.]|/' '{print $(NF-1)}')
		case $domain in
#			facebook) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
			*)
				siteVideoFormat=$initialSiteVideoFormat
			;;
		esac
		formats=( $(echo $siteVideoFormat | \sed "s/,/ /g") )

		echo "=> Fetching the generated destination filename(s) if \"$url\" still exists ..."
		errorLogFile="youtube-dl_errors_$$.log"
		local fileNames=()
		local remoteFileSizes=()
		local -i i=0
		while read fileName remoteFileSize
		do
			fileNames+=($fileName)
			remoteFileSizes+=($remoteFileSize)
#			echo -e "${fileNames[$i]}\t${remoteFileSizes[$i]}";let i++
		done < <(time command youtube-dl --restrict-filenames -f "$siteVideoFormat" -o "$youtube_dl_FileNamePattern" -j -- "$url" 2>$errorLogFile | jq -r '._filename,.filesize' | paste - -)

		grep -A1 ERROR: $errorLogFile && echo && continue || \rm $errorLogFile
		echo

		local -i j=0
		for fileName in "${fileNames[@]}"
		do
			echo "=> Downloading $url using the <${formats[$j]}> format ..."
			echo
			extension="${fileName/*./}"
			chosenFormatID=$(echo "$fileName" | awk -F '__' '{print$2}')
			if [ -f "$fileName" ] && [ $isLIVE = false ]; then
				echo "=> The file <$fileName> is already exists, comparing it's size with the remote file ..." 1>&2
				echo
				fileSizeOnFS=$(stat -c %s "$fileName")
#				time remoteFileSize=$(command youtube-dl --ignore-config -j -f $chosenFormatID $url | jq -r .filesize)
				remoteFileSize=${remoteFileSizes[$j]}
				test $? != 0 && return
				[ $remoteFileSize = null ] && remoteFileSize=-1
				if [ ! -w "$fileName" ] || [ $fileSizeOnFS -ge $remoteFileSize ]; then
					echo
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded ang greater or equal to remote file, skipping ...$normal" 1>&2
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

			( [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] ) && test $AtomicParsley && embedThumbnail="--embed-thumbnail" || embedThumbnail="--write-thumbnail"

			echo
			echo "=> The download is now starting ..."
			echo
				time LANG=C.UTF-8 command youtube-dl -o "$fileName" -f "${formats[$j]}" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail
				downloadOK=$?
				test $downloadOK != 0 && {
					errorLogFile="youtube-dl_errors_$$.log"
					time LANG=C.UTF-8 command youtube-dl -o $fileName -f "${formats[$j]}" "$url" 2>$errorLogFile
					downloadOK=$?
					egrep -A1 'ERROR:.*' $errorLogFile && downloadOK=1 && return 1 || \rm $errorLogFile
				}

			echo
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
					echo "=> ADDING COVER TO THE OGG CONTAINER IS NOT IMPLEMENTED YET"
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
