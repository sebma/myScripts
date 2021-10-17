#!/usr/bin/env bash

#set -o nounset
[ $BASH_VERSINFO -lt 4 ] && echo "=> [WARNING] BASH_VERSINFO = $BASH_VERSINFO then continuing in bash4 ..." && exec bash4 $0 "$@"

set_colors() {
	local normal=$(tput sgr0)
	if [ $BASH_VERSINFO -ge 4 ];then
		export escapeChar=$'\e'
		export blinkOff=${escapeChar}'[25m'
		declare -Ag effects=( [bold]=$(tput bold) [dim]=$(tput dim) [italics]=$(tput sitm) [underlined]=$(tput smul) [blink]=$(tput blink) [reverse]=$(tput rev) [hidden]=$(tput invis) [blinkOff]=$blinkOff )
		declare -Ag colors=( [red]=$(tput setaf 1) [green]=$(tput setaf 2) [blue]=$(tput setaf 4) [cyan]=$(tput setaf 6) [yellow]=$(tput setaf 11) [yellowOnRed]=$(tput setaf 11)$(tput setab 1) [greenOnBlue]=$(tput setaf 2)$(tput setab 4) [yellowOnBlue]=$(tput setaf 11)$(tput setab 4) [cyanOnBlue]=$(tput setaf 6)$(tput setab 4) [whiteOnBlue]=$(tput setaf 7)$(tput setab 4) [redOnGrey]=$(tput setaf 1)$(tput setab 7) [blueOnGrey]=$(tput setaf 4)$(tput setab 7) )
	else
		export escapeChar=$'\033'
	fi
}

LANG=C.UTF-8
scriptBaseName=${0/*\//}
scriptExtension=${0/*./}
funcName=${scriptBaseName/.$scriptExtension/}

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=127;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;exit $rc' INT

	set_colors

	if [ $# -le 1 ];then
		echo "=> [$FUNCNAME] Usage : $scriptBaseName initialSiteVideoFormat url1 url2 ..." 1>&2
		return 1
	fi

	local ytdlExtraOptions=()
	local ytdlInitialOptions=()
	local translate=cat
	local siteVideoFormat downloadOK=-1 extension fqdn fileSizeOnFS=0 remoteFileSize=0
	local protocolForDownload=null
	local -i i=0
	local -i j=0
	local acodec=null
	local isLIVE=false
	local jsonResults=null
	local channel_id=null
	local channel_url=null
	local metadataURLFieldName=description
	local embedThumbnail="--write-thumbnail"
	local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__%(extractor)s.%(ext)s"
	local thumbnailerName=$(basename $(which AtomicParsley 2>/dev/null || which ffmpeg 2>/dev/null))
	local thumbnailerExecutable=$(which $thumbnailerName 2>/dev/null)
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
	local userAgent=null
	local tool=null
	local debug="set +x"
	local undebug="set +x"
	local downloader=yt-dlp

#	local youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command
	videoDownloader () {
		LANG=C.UTF-8 $downloader "$@"
	}

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
	echo $scriptOptions | $grep -q -- "-p" && playlistFileName=$2 && shift 2
	echo $scriptOptions | $grep -q -- "-v" && debug="set -x"
	echo $scriptOptions | $grep -q -- "-vv" && debug="set -x" && ytdlInitialOptions+=( -v )
	echo $scriptOptions | $grep -q -- "-vvv" && debug="set -x" && ffmpegLogLevel=$ffmpegInfoLogLevel

	initialSiteVideoFormat="$1"
	shift

	time videoDownloader --rm-cache
	for url
	do
		let i++
		numberOfURLsToDownload=$#
		echo
		echo "=> Downloading url # $i/$# ..."
		echo
		echo $url | egrep -wq "https?:" || url=https://www.youtube.com/watch?v=$url
		fqdn=$(echo "$url" | cut -d/ -f3)
		[ $fqdn = youtu.be ] && fqdn=www.youtube.com
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		sld=$(echo $fqdn | awk -F '.' '{print $(NF-1)}') # Single level domain
		domainStringForFilename=$(echo $domain | tr . _)

		case $sld in
#			facebook) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
			*) siteVideoFormat=$initialSiteVideoFormat ;;
		esac
		formats=( $(echo $siteVideoFormat | \sed "s/,/ /g") )

		errorLogFile="${downloader}_errors_$$.log"
		youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__$domainStringForFilename.%(ext)s"
		jsonResults=null
		ytdlExtraOptions=( "${ytdlInitialOptions[@]}" )
		echo "$url" | grep -q /live$ && ytdlExtraOptions+=( --playlist-items 1 )
		[ $downloader = yt-dlp ] && ytdlExtraOptions+=( --format-sort +proto )

		printf "=> Fetching the generated destination filename(s) for \"$url\" with $downloader at %s ...\n" "$(LC_MESSAGES=en date)"
		jsonResults=$(time videoDownloader --restrict-filenames -f "$siteVideoFormat" -o "${youtube_dl_FileNamePattern}" -j "${ytdlExtraOptions[@]}" -- "$url" 2>$errorLogFile | $jq -r .)
		# ytdlExtraOptions+= ( --exec 'basename %(filepath)s .%(ext)s' --write-info-json )
		# jsonFileList=$(egrep -v "^(Deleting |\[)|\[download\]" ytdlpOutput.txt | sed -z "s/\n/.info.json /g")
		formatsIDs=( $(echo "$jsonResults" | $jq -r .format_id | awk '!seen[$0]++') ) # Remove duplicate lines i.e: https://stackoverflow.com/a/1444448/5649639
		echo

		$grepColor -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && continue || \rm $errorLogFile

		test -n "$playlistFileName" && echo '#EXTM3U' > "$playlistFileName"

		time for formatID in "${formatsIDs[@]}"
		do
			let j++
			let numberOfFilesToDownload=$numberOfURLsToDownload*${#formatsIDs[@]}
			$undebug

			jsonHeaders=$(echo "$jsonResults" | $jq -r 'del(.formats, .thumbnails, .automatic_captions, .requested_subtitles)')
			# Extraction d'infos pour le(s) format(s) selectionne(s)
			fileName=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\"))._filename")
			extension=$(echo "$jsonHeaders"| $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).ext")
			formatString=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format")
			chosenFormatID=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format_id")
			remoteFileSize=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).filesize" | sed "s/null/-1/")
			acodec=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).acodec")
			acodec=$(echo $acodec | cut -d. -f1)
			protocolForDownload=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).protocol")

			# Les resultats ci-dessous ne dependent pas du format selectionne
			isLIVE=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .is_live)')
			title=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .title)')
			webpage_url=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .webpage_url)')
			duration=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .duration)')
			thumbnailURL=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .thumbnail)')

			uploader_id=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .uploader_id)')
			channel_id=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .channel_id)')
			channel_url=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .channel_url)')
			uploader_url=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .uploader_url)')
			channelURL=$uploader_url

			# To create an M3U file
			test -n "$playlistFileName" && duration=$($grep '^[0-9]*' <<< $duration || echo -1) && printf "#EXTINF:$duration,$title\n$webpage_url\n" >> "$playlistFileName"

			if [ -z "$acodec" ] || [ $acodec = null ];then
				# Preparing the User Agent for ffprobe
				which chromium-browser>/dev/null 2>&1 && chromeVersion=$(chromium-browser --version 2>/dev/null | awk '{printf$2}') || chromeVersion="73.0.3671.2"
				userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%s Safari/537.36"
				userAgent="$(printf "$userAgent" $chromeVersion)"
				echo "=> Fetching some information from remote stream with ffprobe ..."
				if echo $chosenFormatID | \grep "[+]" -q;then
					audioFormatID=$(echo $formatID | sed "s/.*+//")
					# On utilise "$jsonResults" car on interroge TOUS les formats possibles contenus dans le tableau ".formats[]"
					streamDirectURL="$(echo "$jsonResults" | $jq -n -r "first(inputs | .formats[] | select(.format_id==\"$audioFormatID\")).url")"
				else
					streamDirectURL="$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).url")"
				fi
				ffprobeJSON_Stream_Info=$(time $ffprobe -hide_banner -user_agent "$userAgent" -v error -show_format -show_streams -print_format json "$streamDirectURL")

				if [ $? = 0 ];then
					firstAudioStreamCodecName=$(echo "$ffprobeJSON_Stream_Info" | $jq -r '[ .streams[] | select(.codec_type=="audio") ][0].codec_name')
				else
					echo $normal >&2
					echo "${colors[red]}=> WARNING : Error fetching the <firstAudioStreamCodecName> with ffprobe on the remote direct stream.$normal" >&2
					echo >&2
					unset ffprobeJSON_Stream_Info firstAudioStreamCodecName
				fi
				echo
			else
				firstAudioStreamCodecName=$acodec
			fi

			thumbnailExtension=$(echo "${thumbnailURL/*\//}" | awk -F"[.]" '{print$2}')
			thumbnailExtension="${thumbnailExtension/\?*/}"
			[ -z "$thumbnailExtension" ] && thumbnailExtension=$(\curl -Lqs "$thumbnailURL" | file -bi - | awk -F ';' '{sub(".*/","",$1);print gensub("jpeg","jpg",1,$1)}')
			[ -n "$thumbnailExtension" ] && artworkFileName=${fileName/%.$extension/.$thumbnailExtension}

			[ "$debug" ] && echo "=> protocolForDownload = <$protocolForDownload> acodec = <$acodec> chosenFormatID = <${effects[bold]}${colors[blue]}$chosenFormatID$normal> fileName = <$fileName> extension = <$extension> isLIVE = <$isLIVE> formatString = <$formatString> thumbnailURL = <$thumbnailURL> thumbnailExtension = <$thumbnailExtension> artworkFileName = <$artworkFileName> firstAudioStreamCodecName = <$firstAudioStreamCodecName> webpage_url = <$webpage_url> title = <$title> duration = <$duration>" && echo

			if [ $thumbnailerName = AtomicParsley ];then
				thumbnailFormatString=$(\curl -Lqs "$thumbnailURL" | file -b -)
				if echo $thumbnailFormatString | $grep -q JPEG && ! echo $thumbnailFormatString | $grep -q JFIF;then
					#Because of https://bitbucket.org/wez/atomicparsley/issues/63
					echo "${effects[bold]}${colors[blue]}=> WARNING: The remote thumbnail is not JFIF compliant, downloading it to convert it to JPEG JFIF ...$normal"
					if \curl -qLs "$thumbnailURL" -o "$artworkFileName.tmp";then
						echo "=> Converting <$artworkFileName> to JPEG JFIF for AtomicParsley ..."
						convert "$artworkFileName.tmp" "$artworkFileName" && rm -f "$artworkFileName.tmp"
						echo "=> Done."
						echo
						[ "$debug" ] && file "$artworkFileName"
						[ "$debug" ] && ls -l --time-style=+'%Y-%m-%d %T' "$artworkFileName"
						echo
					fi
				fi
			fi

			echo $formatString | $grep -v '+' | $grep "audio only" -q && ytdlExtraOptions+=( -x )
			if echo "${ytdlExtraOptions[@]}" | $grep -w "\-x" -q;then
				extension=$(getAudioExtension $firstAudioStreamCodecName) || continue
				( [ $extension = m4a ] || [ $extension = opus ] ) && ytdlExtraOptions+=( -k )
				newFileName="${fileName/.*/.$extension}"
			else
				newFileName="$fileName"
			fi

			[ "$debug" ] && echo "=> newFileName = <$newFileName>" && echo

			[ $isLIVE = true ] && url="$webpage_url"
			echo "=> Downloading <$url> using the <${effects[bold]}${colors[blue]}$chosenFormatID$normal> $sld format ..."
			echo

			ytdlExtraOptions+=( --add-metadata --prefer-ffmpeg --restrict-filenames --embed-subs --write-auto-sub --sub-lang='en,fr,es,de' )
			if [ $isLIVE = true ];then
				ytdlExtraOptions+=( --hls-use-mpegts --hls-prefer-ffmpeg )
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
					continue
				fi
			fi

			echo "=> fileName to be downloaded = <$fileName>"
			echo

			[ $thumbnailerName = AtomicParsley ] && ( [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = m4b ] || [ $extension = mp3 ] ) && embedThumbnail="--embed-thumbnail"

			echo "=> Downloading file # $j/$numberOfFilesToDownload ..."
			echo
			printf "=> Starting $downloader at %s ...\n" "$(LC_MESSAGES=en date)"
			echo
			errorLogFile="${downloader}_errors_$$.log"
			trap - INT
			$debug
			time videoDownloader -v --ignore-config -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
			downloadOK=$?
			$undebug
			sync
			echo

			$grepColor -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && continue || \rm $errorLogFile

			if echo "${ytdlExtraOptions[@]}" | $grep -qw -- "-x";then
				extension=$(getAudioExtension $firstAudioStreamCodecName) || continue
				fileName="${fileName/.*/.$extension}"
			fi

			fileSizeOnFS=$(stat -c %s "$fileName" || echo 0)
			if [ $fileSizeOnFS -ge $remoteFileSize ] || [ $downloadOK = 0 ]; then
				addThumbnail2media "$fileName" "$artworkFileName"
			else
				time videoDownloader -o $fileName -f "$chosenFormatID" "$url" 2>$errorLogFile
				downloadOK=$?
				echo

				$grepColor -A1 'ERROR:.*' $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && return $downloadOK || \rm $errorLogFile
			fi
			$undebug

			if [ $downloadOK = 0 ]; then
				ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
				videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)
				videoContainersList=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name)

				if [ $videoContainer = mov ];then
					if [ $channelURL = null ];then
						addURLs2mp4Metadata "$url" "$fileName"
					else
						addURLs2mp4Metadata "$url
Channel URL : $channelURL" "$fileName"
					fi
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
webp2jpg () {
	local image
	for image
	do
		if identify "$image" | \grep -q "no decode delegate for this image format"; then
			dwebp "$image" -o - 2> /dev/null | convert - "${image/.webp/.jpg}"
		else
			convert "$image" "${image/.webp/.jpg}"
		fi
	done
}
getAudioExtension () {
	if [ $# != 1 ];then
		echo "=> [$FUNCNAME] Usage: $FUNCNAME ffprobeAudioCodecName" 1>&2
		return 1
	fi

	local acodec=$1
	local audioExtension=unknown

	if [ $BASH_VERSINFO -ge 4 ];then
		declare -A audioExtension=( [libspeex]=spx [speex]=spx [opus]=opus [vorbis]=ogg [aac]=m4a [mp4a]=m4a [mp3]=mp3 [mp2]=mp2 [ac3]=ac3 [wmav2]=wma [pcm_dvd]=wav [pcm_s16le]=wav )
		audioExtension=${audioExtension[$acodec]}
	else
		case $acodec in
			libspeex|speex) audioExtension=spx;;
			opus|mp2|mp3|ac3) audioExtension=$acodec;;
			vorbis) audioExtension=ogg;;
			aac|mp4a) audioExtension=m4a;;
			wmav2) audioExtension=wma;;
			pcm_dvd|pcm_s16le) audioExtension=wav;;
			*) audioExtension=unknown;;
		esac
	fi
	echo $audioExtension
}
addURLs2mp4Metadata() {
	if [ $# != 2 ];then
		echo "=> Usage: $FUNCNAME url mediaFile" 1>&2
		exit 1
	fi

	local url="$1"
	local fileName=$2
	local retCode=-1
	local timestampFileRef=$(mktemp)
	touch -r "$fileName" $timestampFileRef
	if which ffmpeg >/dev/null 2>&1;then
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

		echo "[ffmpeg] Adding '$url' to '$fileName' description metadata"
		time $ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -metadata $metadataURLFieldName="$url" "$outputVideo"
		retCode=$?
		[ $retCode = 0 ] && sync && \mv -f "$outputVideo" "$fileName"
	elif which mp4tags >/dev/null 2>&1;then
		echo "[mp4tags] Adding '$url' to '$fileName' description metadata"
		time mp4tags -m "$url" "$fileName"
		retCode=$?
	fi

	[ $retCode = 0 ] && touch -r $timestampFileRef "$fileName"
	\rm $timestampFileRef
	return $retCode
}
function addSubtitles2media {
	local inputVideo=$1
	test $# -le 1 && {
		echo "=> Usage: $FUNCNAME inputVideo subFile1 subFile2 subFile3 ..." 1>&2
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
	local retCode=0

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
	local possibleFormats="22/bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
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
	local possibleFormats="18/bestvideo[ext=mp4][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
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
