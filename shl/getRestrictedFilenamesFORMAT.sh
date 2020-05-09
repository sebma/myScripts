#!/usr/bin/env bash

#set -o nounset
[ $BASH_VERSINFO -lt 4 ] && echo "=> [WARNING] BASH_VERSINFO = $BASH_VERSINFO then continuing in bash4 ..." && exec bash4 $0 "$@"
[ $BASH_VERSINFO -ge 4 ] && declare -A colors=( [red]=$(tput setaf 1) [green]=$(tput setaf 2) [blue]=$(tput setaf 4) [cyan]=$(tput setaf 6) [yellow]=$(tput setaf 11) [yellowOnRed]=$(tput setaf 11)$(tput setab 1) [greenOnBlue]=$(tput setaf 2)$(tput setab 4) [yellowOnBlue]=$(tput setaf 11)$(tput setab 4) [cyanOnBlue]=$(tput setaf 6)$(tput setab 4) [whiteOnBlue]=$(tput setaf 7)$(tput setab 4) [redOnGrey]=$(tput setaf 1)$(tput setab 7) [blueOnGrey]=$(tput setaf 4)$(tput setab 7) )

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}
youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=127;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT

	if [ $# -le 1 ];then
		echo "=> [$FUNCNAME] Usage : $scriptBaseName initialSiteVideoFormat url1 url2 ..."
		return 1
	fi

	local ytdlExtraOptions="--add-metadata"
	local translate=cat
	local siteVideoFormat downloadOK=-1 extension fqdn fileSizeOnFS=0 remoteFileSize=0
	local -i i=0
	local -i j=0
	local isLIVE=false
	local jsonResults=null
	local metadataURLFieldName=description
	local embedThumbnail="--write-thumbnail"
	local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__%(extractor)s.%(ext)s"
	local thumbnailerName=$(basename $(which AtomicParsley 2>/dev/null || which ffmpeg 2>/dev/null))
	local thumbnailerExecutable=$(which $thumbnailerName 2>/dev/null)
	local retCode=-1
	local ffmpegNormalLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegNormalLogLevel
	local ffprobeJSON_File_Info=null
	local videoContainer=null
	local latestVideoStreamCodecName=null
	local mimetype=null
	local timestampFileRef=null
	local domainStringForFilename=null
	local fqdn=null domain=null sld=null
	local errorLogFile=null
	local youtube_dl_FileNamePattern=null
	local scriptOptions=null
	local initialSiteVideoFormat=null
	local numberOfURLsToDownload=null
	local formats=null
	local formatsIDs=null
	local thumbnailExtension=null
	local artworkFileName=null
	local tool=null
	local undebug="set +x"

	for tool in ffmpeg ffprobe jq;do
		local $tool="$(which $tool)"
		if [ -z "${!tool}" ];then
			echo "=> [$FUNCNAME] ERROR: $tool is required, you need to install it." >&2
			return 2
		fi
	done

	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"

	echo $1 | grep -q -- "^-[a-z]" && scriptOptions=$1 && shift
	echo $scriptOptions | \egrep -q -- "-x" && ytdlExtraOptions+=( -x )
	echo $scriptOptions | \egrep -q -- "-v" && debug="set -x"
	echo $scriptOptions | \egrep -q -- "-vv" && debug="set -x" && ytdlExtraOptions+=( -v )
	echo $scriptOptions | \egrep -q -- "-vvv" && debug="set -x" && ffmpegLogLevel=$ffmpegInfoLogLevel

	initialSiteVideoFormat="$1"
	shift

	youtube-dl --rm-cache
	for url
	do
		let i++
		numberOfURLsToDownload=$#
		echo "=> Downloading url # $i/$# ..."
		echo
		echo $url | egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url
		fqdn=$(echo "$url" | cut -d/ -f3)
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		domainStringForFilename=$(echo $domain | tr . _)
		sld=$(echo $fqdn | awk -F '.' '{print $(NF-1)}')
		case $sld in
#			facebook) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
			*)
				siteVideoFormat=$initialSiteVideoFormat
			;;
		esac
		formats=( $(echo $siteVideoFormat | \sed "s/,/ /g") )

		echo "=> Fetching the generated destination filename(s) for \"$url\" ..."
		errorLogFile="youtube-dl_errors_$$.log"
		youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__$domainStringForFilename.%(ext)s"

		jsonResults=null
		jsonResults=$(time command youtube-dl --restrict-filenames -f "$siteVideoFormat" -o "$youtube_dl_FileNamePattern" -j -- "$url" 2>$errorLogFile | $jq -r .)
		formatsIDs=( $(echo "$jsonResults" | $jq -r .format_id | awk '!seen[$0]++') ) # Remove duplicate lines i.e: https://stackoverflow.com/a/1444448/5649639
		echo

		grep -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && continue || \rm $errorLogFile

		for formatID in "${formatsIDs[@]}"
		do
			let j++
			let numberOfFilesToDownload=$numberOfURLsToDownload*${#formatsIDs[@]}
			$undebug
			fileName=$(echo "$jsonResults"  | $jq -n -r "first(inputs | select(.format_id==\"$formatID\"))._filename")
			extension=$(echo "$jsonResults" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).ext")
			thumbnailURL=$(echo "$jsonResults" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).thumbnail")
			formatString=$(echo "$jsonResults"  | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format")
			chosenFormatID=$(echo "$jsonResults"  | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format_id")
			streamDirectURL="$(echo "$jsonResults"  | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).url")"
			remoteFileSize=$(echo "$jsonResults" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).filesize" | sed "s/null/-1/")
			isLIVE=$(echo "$jsonResults" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).is_live")
			ffprobeJSON_Stream_Info=$($ffprobe -hide_banner -v error -show_format -show_streams -print_format json "$streamDirectURL")
			latestAudioStreamCodecName=$(echo "$ffprobeJSON_Stream_Info" | $jq -r '[ .streams[] | select(.codec_type=="audio") ][-1].codec_name')

			thumbnailExtension=$(echo "${thumbnailURL/*\//}" | awk -F"[.]" '{print$2}')
			[ -z "$thumbnailExtension" ] && thumbnailExtension=$(\curl -qs "$thumbnailURL" | file -bi - | awk -F ';' '{sub(".*/","",$1);print gensub("jpeg","jpg",1,$1)}')
			[ -n "$thumbnailExtension" ] && artworkFileName=${fileName/.$extension/.$thumbnailExtension}

			if [ $thumbnailerName = AtomicParsley ] && ! \curl -qs "$thumbnailURL" | file -b - | \grep -q JFIF;then # because of https://bitbucket.org/wez/atomicparsley/issues/63
				if \curl -qs "$thumbnailURL" -o "$artworkFileName.tmp";then
					echo "=> Converting <$artworkFileName> to JPEG JFIF for AtomicParsley ..."
					convert -verbose "$artworkFileName.tmp" "$artworkFileName" && rm -f "$artworkFileName.tmp"
					echo "=> Done."
					echo
				fi
			fi

			echo $formatString | \grep -v '+' | \grep -q "audio only" && ytdlExtraOptions+=( -x )

			if echo $formatString | \grep -v '+' | \grep -q "audio only" || echo "${ytdlExtraOptions[@]}" | \grep -qw -- "-x" ;then
				case $extension in
					webm) extension=opus && fileName="${fileName/.webm/.opus}" ;;
					mp4) extension=m4a && fileName="${fileName/.mp4/.m4a}" ;;
					*) ;;
				esac
			fi

			[ "$debug" ] && echo "=> chosenFormatID = <$chosenFormatID>  fileName = <$fileName>  extension = <$extension>  isLIVE = <$isLIVE>  formatString = <$formatString> thumbnailURL = <$thumbnailURL> artworkFileName = <$artworkFileName>  latestAudioStreamCodecName = <$latestAudioStreamCodecName>" && echo

			echo "=> Downloading <$url> using the <$chosenFormatID> $sld format ..."
			echo

			ytdlExtraOptions+=( --prefer-ffmpeg --restrict-filenames --embed-subs --write-auto-sub --sub-lang=en,fr,es,de )
			echo $formatString | \grep -v '+' | \grep -q "audio only" && ytdlExtraOptions+=( -x )
			if [ $isLIVE = true ];then
				ytdlExtraOptions+=( --hls-use-mpegts )
			else
				ytdlExtraOptions+=( --hls-prefer-native )
			fi

			$undebug
			[ "$debug" ] && echo "=> ytdlExtraOptions = ${ytdlExtraOptions[@]}"
			echo

			if [ -f "$fileName" ] && [ $isLIVE != true ]; then
				echo "=> The file <$fileName> is already exists, comparing it's size with the remote file ..." 1>&2
				echo
				fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
				test $? != 0 && return
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

			[ $thumbnailerName = AtomicParsley ] && ( [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = m4b ] || [ $extension = mp3 ] ) && embedThumbnail="--embed-thumbnail"

			echo "=> Downloading file # $j/$numberOfFilesToDownload ..."
			echo
			printf "=> Starting youtube-dl at %s ...\n" "$(LC_MESSAGES=en date)"
			echo
			echo "=> ytdlExtraOptions = ${ytdlExtraOptions[@]}"
			echo
			errorLogFile="youtube-dl_errors_$$.log"
			$debug
			time LANG=C.UTF-8 command youtube-dl -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
			downloadOK=$?
			$undebug
			sync
			echo

			grep -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && continue || \rm $errorLogFile

			fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
			ffprobeJSON_File_Info=$($ffprobe -hide_banner -v error -show_format -show_streams -print_format json "$fileName")

			videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)
#			numberOfVideoStreams=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ] | length'
			latestVideoStreamCodecName=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ][-1].codec_name')

			major_brand=$(echo $ffprobeJSON_File_Info | $jq -r .format.tags.major_brand)

			[ "$debug" ] && echo "=> videoContainer = <$videoContainer>  latestVideoStreamCodecName = <$latestVideoStreamCodecName> major_brand = <$major_brand>" && echo

			if [ $fileSizeOnFS -ge $remoteFileSize ] || [ $downloadOK = 0 ]; then
				if [ -s "$artworkFileName" ] && [ "$latestVideoStreamCodecName" != mjpeg ] && [ "$latestVideoStreamCodecName" != png ];then
					mimetype=$(file -bi "$artworkFileName" | cut -d';' -f1)
					timestampFileRef=$(mktemp) && touch -r "$fileName" $timestampFileRef
					if [ $videoContainer = mov ];then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						[ $major_brand = M4A ] && disposition_stream_specifier=v:0 || disposition_stream_specifier=v:1
						$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -disposition:$disposition_stream_specifier attached_pic "${fileName/.$extension/_NEW.$extension}"
						retCode=$?
						if [ $retCode = 0 ];then
							sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
						else
							set -x
							$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -disposition:$disposition_stream_specifier attached_pic "${fileName/.$extension/_NEW.$extension}"
							set +x
							\rm "${fileName/.$extension/_NEW.$extension}"
						fi
					elif [ $videoContainer = mp3 ];then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -map_metadata 0 "${fileName/.$extension/_NEW.$extension}"
						retCode=$?
						if [ $retCode = 0 ];then
							sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
						else
							set -x
							$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -map_metadata 0 "${fileName/.$extension/_NEW.$extension}"
							set +x
							\rm "${fileName/.$extension/_NEW.$extension}"
						fi
					elif [ $videoContainer = matroska ];then
						echo "[ffmpeg] Adding thumbnail to '$fileName'"
						$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -attach "$artworkFileName" -metadata:s:t mimetype=$mimetype "${fileName/.$extension/_NEW.$extension}"
						retCode=$?
						if [ $retCode = 0 ];then
							sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName" && rm "$artworkFileName" && downloadOK=0
						else
							set -x
							$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -map 0 -c copy -attach "$artworkFileName" -metadata:s:t mimetype=$mimetype "${fileName/.$extension/_NEW.$extension}"
							set +x
							\rm "${fileName/.$extension/_NEW.$extension}"
						fi
					elif [ $videoContainer = ogg ];then
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

				egrep -A1 'ERROR:.*' $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && return $downloadOK || \rm $errorLogFile
			fi
			$undebug

			if [ $downloadOK = 0 ]; then
				if [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = mp3 ];then
					timestampFileRef=$(mktemp) && touch -r "$fileName" $timestampFileRef
					metadataURLFieldName=description
					echo "[ffmpeg] Adding '$url' to '$fileName' metadata"
					$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -metadata $metadataURLFieldName="$url" "${fileName/.$extension/_NEW.$extension}" && sync && mv "${fileName/.$extension/_NEW.$extension}" "$fileName"
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
