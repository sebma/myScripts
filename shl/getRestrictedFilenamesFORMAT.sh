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
	local -i j=0
	local isLIVE=false
	local ffmpeg="$(which ffmpeg) -hide_banner"
	local metadataURLFieldName=description
	local embedThumbnail="--write-thumbnail"
	local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__%(extractor)s.%(ext)s"
	local AtomicParsley=$(which AtomicParsley 2>/dev/null)

	for url
	do
		let i++
		local numberOfURLsToDownload=$#
		echo "=> Downloading url # $i/$# ..."
		echo
		echo $url | egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url
		local urlBase=$(echo "$url" | cut -d/ -f1-3)
		local fqdn=$(echo "$url" | cut -d/ -f3 | awk -F. '{print$(NF-1)"."$NF}')
		local fqdnStringForFilename=$(echo $fqdn | tr . _)
		local domain=$(echo $fqdn | awk -F '[.]|/' '{print $(NF-1)}')
		case $domain in
#			facebook) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
			*)
				siteVideoFormat=$initialSiteVideoFormat
			;;
		esac
		local formats=( $(echo $siteVideoFormat | \sed "s/,/ /g") )

		echo "=> Fetching the generated destination filename(s) for \"$url\" ..."
		local errorLogFile="youtube-dl_errors_$$.log"
		local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__$fqdnStringForFilename.%(ext)s"

		local jsonResults=$(time command youtube-dl --restrict-filenames -f "$siteVideoFormat" -o "$youtube_dl_FileNamePattern" -j -- "$url" 2>$errorLogFile | jq -r .)
		local formatsIDs=( $(echo "$jsonResults" | jq -r .format_id | awk '!seen[$0]++') )
		echo

		grep -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && continue || \rm -v $errorLogFile

		for formatID in "${formatsIDs[@]}"
		do
			let j++
			let numberOfFilesToDownload=$numberOfURLsToDownload*${#formatsIDs[@]}
			fileName=$(echo "$jsonResults"  | jq -n -r "first(inputs | select(.format_id==\"$formatID\"))._filename")
			extension=$(echo "$jsonResults" | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).ext")
			thumbnailURL=$(echo "$jsonResults" | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).thumbnail")
			formatString=$(echo "$jsonResults"  | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format")
			chosenFormatID=$(echo "$jsonResults"  | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format_id")
			isLIVE=$(echo "$jsonResults" | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).is_live")

			thumbnailExtension=$(echo "${thumbnailURL/*\//}" | awk -F"[.]" '{print$2}')
			[ -z "$thumbnailExtension" ] && thumbnailExtension=$(\curl -qs "$thumbnailURL" | file -bi - | awk -F ';' '{print gensub(".*/","",1,$1)}' | sed 's/jpeg/jpg/')
			[ -n "$thumbnailExtension" ] && artworkFileName=${fileName/.$extension/.$thumbnailExtension}

#			echo "=> chosenFormatID = <$chosenFormatID>  fileName = <$fileName>  extension = <$extension>  isLIVE = <$isLIVE>  formatString = <$formatString> thumbnailURL = <$thumbnailURL> artworkFileName = <$artworkFileName>";echo

			echo "=> Downloading <$url> using the <$chosenFormatID> $domain format ..."
			echo

			if [ $BASH_VERSINFO -ge 4 ];then
				echo $formatString | \grep -v '+' | \grep -q "audio only" && ytdlExtraOptions+=( -x )
				if [ $isLIVE = true ];then
					ytdlExtraOptions+=( --embed-subs --write-auto-sub --sub-lang=en,fr,es,de --external-downloader ffmpeg --external-downloader-args "-movflags frag_keyframe+empty_moov" )
				else
					ytdlExtraOptions+=( --embed-subs --write-auto-sub --sub-lang=en,fr,es,de --hls-prefer-native )
				fi
			else
				echo $formatString | \grep -v '+' | \grep -q "audio only" && ytdlExtraOptions+=" -x"
				if [ $isLIVE = true ];then
					ytdlExtraOptions+=" --embed-subs --write-auto-sub --sub-lang=en,fr,es,de --external-downloader ffmpeg --external-downloader-args -movflags\\ frag_keyframe+empty_moov"
				else
					ytdlExtraOptions+=" --embed-subs --write-auto-sub --sub-lang=en,fr,es,de --hls-prefer-native"
				fi
			fi

			if [ -f "$fileName" ] && [ $isLIVE != true ]; then
				echo "=> The file <$fileName> is already exists, comparing it's size with the remote file ..." 1>&2
				echo
				fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
				remoteFileSize=$(echo "$jsonResults" | jq -n -r "first(inputs | select(.format_id==\"$formatID\")).filesize")
				test $? != 0 && return
				[ $remoteFileSize = null ] && remoteFileSize=-1
				if [ ! -w "$fileName" ] || [ $fileSizeOnFS -ge $remoteFileSize ]; then
					echo
					echo "${colors[yellowOnBlue]}=> The file <$fileName> is already downloaded ang greater or equal to remote file, skipping ...$normal" 1>&2
					echo
					continue
				fi
			fi

			echo "=> fileName to be downloaded = <$fileName>"
			echo
			trap - INT

			( [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ] ) && embedThumbnail="--write-thumbnail"

			echo "=> Downloading file # $j/$numberOfFilesToDownload ..."
			echo
			errorLogFile="youtube-dl_errors_$$.log"
			time LANG=C.UTF-8 command youtube-dl -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
			downloadOK=$?
			sync
			echo

			grep -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && continue || \rm -v $errorLogFile

			echo $formatString | \grep -v '+' | \grep -q "audio only" && extension=opus && fileName="${fileName/.webm/.opus}"

			fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
			videoContainer=$(command ffprobe -hide_banner -v error -show_format -of json "$fileName" | jq -r .format.format_name)
			embeddedArtworkCodecName=$(command ffprobe -hide_banner -v error -show_streams -of json "$fileName" | jq -r '[ .streams[] | select(.codec_type=="video") ][1].codec_name')
			if [ $fileSizeOnFS -ge $remoteFileSize ] || [ $downloadOK = 0 ]; then
				if [ -s "$artworkFileName" ] && [ "$embeddedArtworkCodecName" = null ];then
					local mimetype=$(file -bi "$artworkFileName" | cut -d';' -f1)
					local timestampFileRef=$(mktemp) && touch -r "$fileName" $timestampFileRef
					if echo $videoContainer | \grep -qw mp4; then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						$ffmpeg -loglevel repeat+error -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "${fileName/.$extension/_NEW.$extension}"
						[ $? = 0 ] && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
					elif echo $videoContainer | \grep -qw mp3; then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						$ffmpeg -loglevel repeat+error -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -map_metadata 0 "${fileName/.$extension/_NEW.$extension}"
						[ $? = 0 ] && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
					elif echo $videoContainer | \grep -qw matroska; then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						$ffmpeg -loglevel repeat+error -i "$fileName" -map 0 -c copy -attach "$artworkFileName" -metadata:s:t mimetype=$mimetype "${fileName/.$extension/_NEW.$extension}"
						[ $? = 0 ] && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
					elif echo $videoContainer | \grep -qw ogg; then
# Complicated with the "METADATA_BLOCK_PICTURE" ogg according to https://superuser.com/a/706808/528454 and https://xiph.org/flac/format.html#metadata_block_picture use another tool instead
						echo "=> ADDING COVER TO THE OGG CONTAINER IS NOT IMPLEMENTED YET"
						\rm "$artworkFileName"
						downloadOK=0
					fi
					touch -r $timestampFileRef "$fileName" && \rm $timestampFileRef
				fi
			else
				time LANG=C.UTF-8 command youtube-dl -o $fileName -f "$chosenFormatID" "$url" 2>$errorLogFile
				downloadOK=$?
				echo

				egrep -A1 'ERROR:.*' $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && return $downloadOK || \rm -v $errorLogFile
			fi

			if [ $downloadOK = 0 ]; then
				if [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ];then
					timestampFileRef=$(mktemp) && touch -r "$fileName" $timestampFileRef
					metadataURLFieldName=description
					echo "[ffmpeg] Adding '$url' to '$fileName' metadata"
					$ffmpeg -loglevel repeat+error -i "$fileName" -map 0 -c copy -metadata $metadataURLFieldName="$url" "${fileName/.$extension/_NEW.$extension}" && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName"
					touch -r $timestampFileRef "$fileName" && \rm $timestampFileRef
				fi
				chmod -w "$fileName"
				echo
				videoInfo.sh "$fileName"
			fi
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
