#!/usr/bin/env bash

#set -o nounset
[ $BASH_VERSINFO -lt 4 ] && echo "=> [WARNING] BASH_VERSINFO = $BASH_VERSINFO then continuing in bash4 ..." && exec bash4 $0 "$@"

set_colors() {
	[ $BASH_VERSINFO -ge 4 ] && declare -Ag colors=( [red]=$(tput setaf 1) [green]=$(tput setaf 2) [blue]=$(tput setaf 4) [cyan]=$(tput setaf 6) [yellow]=$(tput setaf 11) [yellowOnRed]=$(tput setaf 11)$(tput setab 1) [greenOnBlue]=$(tput setaf 2)$(tput setab 4) [yellowOnBlue]=$(tput setaf 11)$(tput setab 4) [cyanOnBlue]=$(tput setaf 6)$(tput setab 4) [whiteOnBlue]=$(tput setaf 7)$(tput setab 4) [redOnGrey]=$(tput setaf 1)$(tput setab 7) [blueOnGrey]=$(tput setaf 4)$(tput setab 7) )
}

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}

getAudioExtension () {
	if [ $# != 1 ];then
		echo "=> [$FUNCNAME] Usage: $FUNCNAME ffprobeAudioCodecName"
		return 1
	fi
	
	local acodec=$1
	local audioExtension=unknown

	if [ $BASH_VERSINFO -ge 4 ];then
		declare -A audioExtension=( [libspeex]=spx [speex]=spx [opus]=opus [vorbis]=ogg [aac]=m4a [mp3]=mp3 [mp2]=mp2 [ac3]=ac3 [wmav2]=wma [pcm_dvd]=wav [pcm_s16le]=wav )
		audioExtension=${audioExtension[$acodec]}
	else
		case $acodec in
			libspeex|speex) audioExtension=spx;;
			opus|mp2|mp3|ac3) audioExtension=$acodec;;
			vorbis) audioExtension=ogg;;
			aac) audioExtension=m4a;;
			wmav2) audioExtension=wma;;
			pcm_dvd|pcm_s16le) audioExtension=wav;;
			*) audioExtension=unknown;;
		esac
	fi
	echo $audioExtension
}

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=127;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT

	set_colors
	local normal=$(tput sgr0)

	if [ $# -le 1 ];then
		echo "=> [$FUNCNAME] Usage : $scriptBaseName initialSiteVideoFormat url1 url2 ..."
		return 1
	fi

	local ytdlExtraOptions=()
	local ytdlInitialOptions=()
	local youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command
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
	local timestampFileRef=null
	local domainStringForFilename=null
	local fqdn=null domain=null sld=null
	local errorLogFile=null
	local scriptOptions=null
	local initialSiteVideoFormat=null
	local numberOfURLsToDownload=null
	local formats=null
	local formatsIDs=null
	local thumbnailExtension=null
	local artworkFileName=null
	local tool=null
	local undebug="set +x"

	for tool in ffmpeg grep ffprobe jq;do
		local $tool="$(which $tool)"
		if [ -z "${!tool}" ];then
			echo "=> [$FUNCNAME] ERROR: $tool is required, you need to install it." >&2
			return 2
		fi
	done

	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"
	grepColor=$grep
	grep --help | grep -q -- --color && grepColor+=" --color"

	echo $1 | $grep -q -- "^-[a-z]" && scriptOptions=$1 && shift
	echo $scriptOptions | $grep -q -- "-x" && ytdlInitialOptions+=( -x )
	echo $scriptOptions | $grep -q -- "-v" && debug="set -x"
	echo $scriptOptions | $grep -q -- "-vv" && debug="set -x" && ytdlInitialOptions+=( -v )
	echo $scriptOptions | $grep -q -- "-vvv" && debug="set -x" && ffmpegLogLevel=$ffmpegInfoLogLevel

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
		jsonResults=$(time command youtube-dl --restrict-filenames -f "$siteVideoFormat" -o "${youtube_dl_FileNamePattern}" -j -- "$url" 2>$errorLogFile | $jq -r .)
		formatsIDs=( $(echo "$jsonResults" | $jq -r .format_id | awk '!seen[$0]++') ) # Remove duplicate lines i.e: https://stackoverflow.com/a/1444448/5649639
		echo

		$grepColor -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && continue || \rm $errorLogFile

		time for formatID in "${formatsIDs[@]}"
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
			firstAudioStreamCodecName=$(echo "$ffprobeJSON_Stream_Info" | $jq -r '[ .streams[] | select(.codec_type=="audio") ][0].codec_name')

			thumbnailExtension=$(echo "${thumbnailURL/*\//}" | awk -F"[.]" '{print$2}')
			[ -z "$thumbnailExtension" ] && thumbnailExtension=$(\curl -qs "$thumbnailURL" | file -bi - | awk -F ';' '{sub(".*/","",$1);print gensub("jpeg","jpg",1,$1)}')
			[ -n "$thumbnailExtension" ] && artworkFileName=${fileName/.$extension/.$thumbnailExtension}

			[ "$debug" ] && echo "=> chosenFormatID = <$chosenFormatID>  fileName = <$fileName>  extension = <$extension>  isLIVE = <$isLIVE>  formatString = <$formatString> thumbnailURL = <$thumbnailURL> artworkFileName = <$artworkFileName>  firstAudioStreamCodecName = <$firstAudioStreamCodecName>" && echo

			if [ $thumbnailerName = AtomicParsley ] && ! \curl -qs "$thumbnailURL" | file -b - | $grep -q JFIF;then #Because of https://bitbucket.org/wez/atomicparsley/issues/63
				if \curl -qs "$thumbnailURL" -o "$artworkFileName.tmp";then
					echo "=> Converting <$artworkFileName> to JPEG JFIF for AtomicParsley ..."
					echo
					convert -verbose "$artworkFileName.tmp" "$artworkFileName" && rm -f "$artworkFileName.tmp"
					echo
					echo "=> Done."
					echo
				fi
			fi

			ytdlExtraOptions=( "${ytdlInitialOptions[@]}" )
			echo $formatString | $grep -v '+' | $grep -q "audio only" && ytdlExtraOptions+=( -x )

			if echo "${ytdlExtraOptions[@]}" | $grep -qw -- "-x";then
				extension=$(getAudioExtension $firstAudioStreamCodecName)
				( [ $extension = m4a ] || [ $extension = opus ] ) && ytdlExtraOptions+=( -k )
				newFileName="${fileName/.*/.$extension}"
			else
				newFileName="$fileName"
			fi

			[ "$debug" ] && echo "=> newFileName = <$newFileName>" && echo

			echo "=> Downloading <$url> using the <$chosenFormatID> $sld format ..."
			echo

			ytdlExtraOptions+=( --add-metadata --prefer-ffmpeg --restrict-filenames --embed-subs --write-auto-sub --sub-lang='en,fr,es,de' )
			if [ $isLIVE = true ];then
				ytdlExtraOptions+=( --hls-use-mpegts )
			else
				ytdlExtraOptions+=( --hls-prefer-native )
			fi

			$undebug
			[ "$debug" ] && echo "=> ytdlExtraOptions = ${ytdlExtraOptions[@]}" && echo

			if [ -f "$newFileName" ] && [ $isLIVE != true ]; then
				echo "=> The file <$newFileName> already exists, comparing it's size with the remote file ..." 1>&2
				echo 1>&2
				fileSizeOnFS=$(stat -c %s "$newFileName" || echo 0)
				test $? != 0 && return
				if [ ! -w "$newFileName" ] || [ $fileSizeOnFS -ge $remoteFileSize ]; then
					echo "${colors[yellowOnBlue]}=> The file <$newFileName> is already downloaded and greater/equal to the remote, skipping ...$normal" 1>&2
					echo 1>&2
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
			errorLogFile="youtube-dl_errors_$$.log"
			$debug
			time LANG=C.UTF-8 command youtube-dl --ignore-config -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
			downloadOK=$?
			$undebug
			sync
			echo

			$grepColor -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && continue || \rm $errorLogFile

			if echo "${ytdlExtraOptions[@]}" | $grep -qw -- "-x";then
				extension=$(getAudioExtension $firstAudioStreamCodecName)
				fileName="${fileName/.*/.$extension}"
			fi

			fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
			if [ $fileSizeOnFS -ge $remoteFileSize ] || [ $downloadOK = 0 ]; then
				addThumbnail2media "$fileName" "$artworkFileName"
			else
				time LANG=C.UTF-8 command youtube-dl -o $fileName -f "$chosenFormatID" "$url" 2>$errorLogFile
				downloadOK=$?
				echo

				$grepColor -A1 'ERROR:.*' $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && return $downloadOK || \rm $errorLogFile
			fi
			$undebug

			if [ $downloadOK = 0 ]; then
				ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
				videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)

				if [ $videoContainer = mov ];then
					addURL2mp4Metadata "$fileName" "$url"
					subTitleExtension=vtt
				elif [ $videoContainer = matroska ];then
					subTitleExtension=srt
				fi

				[ $extension = m4a ] && \ls "${fileName/.*/}".*.$subTitleExtension >/dev/null 2>&1  && addSubtitles2media "$fileName" "${fileName/.*/}".*.$subTitleExtension
				df -T . | awk '{print$2}' | egrep -q "fuseblk|vfat" || chmod -w "$fileName"
				echo
				videoInfo.sh "$fileName"
			fi
		done
	done
	sync
	set +x
	return $downloadOK
}
addURL2mp4Metadata() {
	if [ $# != 2 ];then
		echo "=> Usage: $FUNCNAME mediaFile url" 1>&2
		exit 1
	fi

	local fileName=$1
	local url=$2
	local extension="${fileName/*./}"
	local outputVideo="${fileName/.$extension/_NEW.$extension}"

	local ffmpeg="$(which ffmpeg)"
	local ffprobe="$(which ffprobe)"
	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"
	local jq="$(which jq)"

	local ffmpegNormalLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegNormalLogLevel

	local ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
	local videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)

	if [ $videoContainer = mov ] || [ $videoContainer = mp3 ];then
		metadataURLFieldName=description
	elif [ $videoContainer = matroska ];then
		metadataURLFieldName=PURL
	fi

	echo "[ffmpeg] Adding '$url' to '$fileName' metadata"
	$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -metadata $metadataURLFieldName="$url" "$outputVideo"
	retCode=$?
	[ $retCode = 0 ] && sync && touch -r "$fileName" "$outputVideo" && \mv -f "$outputVideo" "$fileName"
}
function addSubtitles2media {
	local inputVideo=$1
	test $# -le 1 && {
		echo "=> Usage: $FUNCNAME inputVideo subFile1 subFile2 subFile3 ..." >&2
		return 1
	}

	local extension="${inputVideo/*./}"
	case $extension in
		mp4|m4a|m4b|mov) subTitleCodec=mov_text;;
#		webm|mkv|mka) subTitleCodec=srt;;
		webm|mkv|mka) subTitleCodec=webvtt;;
		ogg|opus) subTitleCodec=not_know_yet;;
		*) subTitleCodec=not_supported;;
	esac

	local ffmpeg="$(which ffmpeg)"
	ffmpeg+=" -hide_banner"
	local ffmpegNormalLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegNormalLogLevel

	local outputVideo="${inputVideo/.$extension/_NEW.$extension}"
	shift
	local numberOfSubtitles=$#
	echo "[ffmpeg] Adding Subtitles to '$fileName'"
	(printf "$ffmpeg -loglevel $ffmpegLogLevel -i $inputVideo ";printf -- "-i %s " "$@";printf -- "-map 0:a? -map 0:v? ";printf -- "-map %d " $(seq $numberOfSubtitles);printf -- "-c copy -c:s $subTitleCodec $outputVideo\n") | sh
	local retCode=$?
	sync
	sleep 1
	touch -r "$inputVideo" "$outputVideo"
	[ $retCode = 0 ] && \mv -f "$outputVideo" "$inputVideo" && \rm "$@"
}
addThumbnail2media() {
	local scriptOptions=null
	echo $1 | \grep -q -- "^-[a-z]" && scriptOptions=$1 && shift

	if [ $# != 2 ];then
		echo "=> Usage: $FUNCNAME [-v] mediaFile artworkFile" 1>&2
		return 1
	fi

	echo $scriptOptions | \grep -q -- "-v" && debug="set -x"
	local fileName="$1"
	local artworkFileName="$2"
	local extension="${fileName/*./}"
	local outputVideo="${fileName/.$extension/_NEW.$extension}"

	local ffmpeg="$(which ffmpeg)"
	local ffprobe="$(which ffprobe)"
	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"
	local jq="$(which jq)"

	local ffmpegNormalLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegNormalLogLevel

	local ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
	local videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)
#	numberOfVideoStreams=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ] | length'
	local latestVideoStreamCodecName=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ][-1].codec_name')

	local major_brand=$(echo $ffprobeJSON_File_Info | $jq -r .format.tags.major_brand)

	[ "$debug" ] && echo "=> videoContainer = <$videoContainer>  latestVideoStreamCodecName = <$latestVideoStreamCodecName> major_brand = <$major_brand>" && echo

	if [ -s "$artworkFileName" ] && [ "$latestVideoStreamCodecName" != mjpeg ] && [ "$latestVideoStreamCodecName" != png ];then
		echo "[ffmpeg] Adding thumbnail to '$fileName'"
		if [ $videoContainer = mov ];then
			[ $major_brand = M4A ] && disposition_stream_specifier=v:0 || disposition_stream_specifier=v:1
			$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -disposition:$disposition_stream_specifier attached_pic "$outputVideo"
			retCode=$?
			if [ $retCode != 0 ];then
				set -x
				$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -disposition:$disposition_stream_specifier attached_pic "$outputVideo"
			fi
		elif [ $videoContainer = mp3 ];then
			$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -map_metadata 0 "$outputVideo"
			retCode=$?
			if [ $retCode != 0 ];then
				set -x
				$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -i "$artworkFileName" -map 0 -map 1 -c copy -map_metadata 0 "$outputVideo"
			fi
		elif [ $videoContainer = matroska ];then
			mimetype=$(file -bi "$artworkFileName" | cut -d';' -f1)
			$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -attach "$artworkFileName" -metadata:s:t mimetype=$mimetype "$outputVideo"
			retCode=$?
			if [ $retCode != 0 ];then
				set -x
				$ffmpeg -loglevel $ffmpegInfoLogLevel -i "$fileName" -map 0 -c copy -attach "$artworkFileName" -metadata:s:t mimetype=$mimetype "$outputVideo"
			fi
		elif [ $videoContainer = ogg ];then
# Complicated with the "METADATA_BLOCK_PICTURE" ogg according to https://superuser.com/a/706808/528454 and https://xiph.org/flac/format.html#metadata_block_picture use another tool instead
			echo "=> ADDING COVER TO THE OGG CONTAINER IS NOT IMPLEMENTED YET"
			\rm "$artworkFileName"
			retCode=-1
		fi
		retCode=$?
		set +x
		sync
		[ $retCode != 0 ] && [ -f "$outputVideo" ] && \rm "$outputVideo"
		[ $retCode = 0 ] && touch -r "$fileName" "$outputVideo" && \mv -f "$outputVideo" "$fileName" && \rm "$artworkFileName"
	else
		retCode=0
	fi
	return $retCode
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

time $funcName $@
