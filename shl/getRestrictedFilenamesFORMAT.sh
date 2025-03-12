#!/usr/bin/env bash

set -o nounset

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

function usage {
	cat <<-EOF >&2
Usage: $scriptBaseName [STRING]...
  or:  $scriptBaseName OPTION

	-d|--debug		be even more verbose
	-h|--help		display this help and exit
	-f|--formats		format(s) of video(s) to download
	-p|--playlist		create M3U playlist
	-t|--timeout		timeout the recording by speficied value (180m by default)
	-v|--verbose		output version information and exit
	-x|--xtrace		set xtrace on
	-y|--overwite		overwrite all downloaded/generated files
	--ffmpeg-i		ffmpeg information log level
	--ffmpeg-w		ffmpeg warning log level
	--ffmpeg-e		ffmpeg error log level
	--yt-dl			change downloader to "youtube-dl" (default is "yt-dlp")
	--ytdl-k		keep downloaded intermediate files
	--ytdl-x		extract audio
	--ytdl-v		set downloader in verbose mode

EOF
	exit 1
}

unset -f getRestrictedFilenamesFORMAT
getRestrictedFilenamesFORMAT () {
	trap 'rc=127;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;exit $rc' INT

	set_colors 2>/dev/null

	local acodec=null
	local artworkFileName=null
	local audioOnly=false
	local channel_id=null
	local channel_url=null
	local debug=""
	local domainStringForFilename=null
	local downloadOK=-1
	local downloader=yt-dlp
	local embedThumbnail="--write-thumbnail"
	local errorLogFile=null
	local extension
	local ffmpegErrorLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegErrorLogLevel
	local ffmpegWarningLogLevel=repeat+warning
	local fileSizeOnFS=0
	local formats=null
	local formatsIDs=null
	local formatsNumber=-1
	local fqdn
	local fqdn=null domain=null sld=null
	local i=0
	local initialSiteVideoFormat=null
	local isLIVE=false
	local j=0
	local jsonResults=null
	local metadataURLFieldName=description
	local numberOfURLsToDownload=null
	local playlistFileName=""
	local protocolForDownload=null
	local remoteFileSize=0
	local scriptOptions=null
	local siteVideoFormat
	local startTime="$(LC_MESSAGES=en date)"
	local thumbnailExtension=null
	local thumbnailerName=$(basename $(type -P AtomicParsley 2>/dev/null || type -P ffmpeg 2>/dev/null))
	local thumbnailerExecutable="command $thumbnailerName 2>/dev/null"
	local timeout=180m
	local timestampFileRef=null
	local tool=null
	local translate=cat
	local undebug="set +x"
	local userAgent=null
	local verboseLevel=0
	local youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__%(extractor)s.%(ext)s"
	local ytdlExtraOptions=()
	local ytdlInitialOptions=()

#	local youtube_dl="eval LANG=C.UTF-8 command youtube-dl" # i.e https://unix.stackexchange.com/questions/505733/add-locale-in-variable-for-command
	function videoDownloader {
		LANG=C.UTF-8 $downloader "$@"
	}

	for tool in ffmpeg ffprobe jq;do
		local $tool="$(type -P $tool)"
		if [ -z "${!tool}" ];then
			echo "=> [$FUNCNAME] ERROR: $tool is required, you need to install it." >&2
			return 2
		fi
	done

	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"

	osFamily=$(uname -s)
	if [ $osFamily = Linux ];then
		date=$(type -P date)
		grep=$(type -P grep)
		stat=$(type -P stat)
	elif [ $osFamily = Darwin ];then
		date=$(type -P gdate)
		grep=$(type -P ggrep)
		stat=$(type -P gstat)
	fi

	grepColor=$grep
	grep --help 2>&1 | grep -q -- --color && grepColor+=" --color"

	function parseArgs {
		osType=$(uname -s)
		if [ $osType = Linux ];then
			if getopt -V | grep getopt.*util-linux -q;then
				export getopt=getopt
			else
				echo "=> ERROR : You must use getopt from util-linux." >&2
				exit 2
			fi
		elif [ $osType = Darwin ];then
			export getopt=/usr/local/opt/gnu-getopt/bin/getopt
		fi

		TEMP=$($getopt -o 'df:hp:t:vxy' --long 'debug,downloader:,ffmpeg-e,ffmpeg-i,ffmpeg-w,formats:,help,playlist:,overwrite,timeout:,verbose,xtrace,yt-dl,ytdl-k,ytdl-x,ytdl-v' -- "$@")

		if [ $? -ne 0 ]; then
			echo 'Terminating...' >&2
			exit 1
		fi

		# Note the quotes around "$TEMP": they are essential!
		eval set -- "$TEMP"
		unset TEMP

		while true; do
			case "$1" in
				-d|--debug) shift
					debug="set -x"
					undebug=""
					ytdlInitialOptions+=( -v )
					;;
				--downloader) shift
					downloader=$1
					shift
					;;
				--ffmpeg-e) shift
					ffmpegLogLevel=$ffmpegErrorLogLevel
					;;
				--ffmpeg-i) shift
					ffmpegLogLevel=$ffmpegInfoLogLevel
					;;
				--ffmpeg-w) shift
					ffmpegLogLevel=$ffmpegWarningLogLevel
					;;
				-f|--formats) shift
					initialSiteVideoFormat="$1"
					shift
					;;
				-h|--help) shift
					usage
					;;
				-p|--playlist) shift
					playlistFileName=$1
					shift
					;;
				-t|--timeout) shift
					timeout=$1
					shift
					;;
				-v|--verbose) shift
					let verboseLevel++
					;;
				--yt-dl) shift
					downloader=youtube-dl
					;;
				--ytdl-k) shift
					ytdlInitialOptions+=( -k )
					;;
				--ytdl-x) shift
					ytdlInitialOptions+=( -x )
					;;
				--ytdl-v) shift
					ytdlInitialOptions+=( -v )
					;;
				-x|--xtrace) shift
					debug="set -x"
					;;
				-y|--overwrite) shift
					overwrite=true
					;;
				-- ) shift; break ;;
				* ) break ;;
			esac
		done
		lastArgs="$@"
	}

	parseArgs "$@"
	eval set -- "$lastArgs"

#	set | egrep "^(getopt|ffmpegLogLevel|verboseLevel|debug|formats|playlistFileName|timeout|downloader|overwrite|ytdlInitialOptions)=" | sort

	echo "=> Started <$scriptBaseName> on $@ at : $startTime ..."
	echo

	time videoDownloader --ignore-config --rm-cache
	for url
	do
		let i++
		numberOfURLsToDownload=$#
		echo
		echo "=> Downloading url # $i/$# ..."
		echo
		if [[ $url =~ ^https?: ]];then
			:
		elif [[ $url =~ ^file:.*/FreeTube/ ]];then # handles FreeTube drag'n'drop URLs
			url=https://youtu.be/$(basename $url)
		else
			url=https://youtu.be/$url
		fi

		fqdn=$(echo "$url" | cut -d/ -f3)
		[ $fqdn = youtu.be ] && fqdn=www.youtube.com
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		sld=$(echo $fqdn | awk -F '.' '{print $(NF-1)}') # Single level domain
		domainStringForFilename=$(echo $domain | tr . _)

		case $sld in
#			facebook) siteVideoFormat=$(echo $initialSiteVideoFormat+m4a | \sed -E "s/^(\(?)\w+/\1bestvideo/g") ;;
			*) siteVideoFormat=$initialSiteVideoFormat ;;
		esac

		errorLogFile="${downloader}_errors_$$.log"
		youtube_dl_FileNamePattern="%(title)s__%(format_id)s__%(id)s__$domainStringForFilename.%(ext)s"
		jsonResults=null
		ytdlExtraOptions=( "${ytdlInitialOptions[@]}" )
		[ $downloader = yt-dlp ] && ytdlExtraOptions+=( --embed-metadata --format-sort +proto )
		# ytdlExtraOptions+= ( --exec 'basename %(filepath)s .%(ext)s' --write-info-json )

		$debug
		printf "=> Fetching the formatsIDs list for \"$url\" for $siteVideoFormat format with ${effects[bold]}${colors[blue]}$downloader$normal at %s ...\n" "$(LC_MESSAGES=en date)"
		$undebug
		jsonResults=$(time videoDownloader --ignore-config --restrict-filenames -f "$siteVideoFormat" -o "${youtube_dl_FileNamePattern}" -j "${ytdlExtraOptions[@]}" -- "$url" 2>$errorLogFile | $jq -r .)
		formatsIDs=( $(echo "$jsonResults" | $jq -r .format_id | awk '!seen[$0]++') ) # Remove duplicate lines i.e: https://stackoverflow.com/a/1444448/5649639
		formatsNumber=${#formatsIDs[@]}
		echo

		[ "$verboseLevel" = 1 ] && echo "=> \$formatsNumber = $formatsNumber"
		[ $formatsNumber = 0 ] && echo "=> ERROR : No format IDs found for $siteVideoFormat" >&2 && exit 1
		[ "$verboseLevel" = 1 ] && echo "=> \${formatsIDs[@]} = ${formatsIDs[@]}"

		test -n "$playlistFileName" && echo '#EXTM3U' > "$playlistFileName"

		time for formatID in "${formatsIDs[@]}"
		do
			let j++
			let numberOfFilesToDownload=$numberOfURLsToDownload*${#formatsIDs[@]}

			videoFormatID=${formatID/+*/}

			jsonHeaders=$(echo "$jsonResults" | $jq -r 'del(.formats, .thumbnails, .automatic_captions, .requested_subtitles)')
			# Extraction d'infos pour le(s) format(s) selectionne(s)
			fileName=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\"))._filename")
			extension=$(echo "$jsonHeaders"| $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).ext")
			formatString=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format")
			chosenFormatID=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).format_id")
			resolution=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).resolution")
			width=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).width")
			height=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).height")

			acodec=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).acodec")
			acodec=$(echo $acodec | cut -d. -f1)
			protocolForDownload=$(echo "$jsonResults" | $jq -n -r "first(inputs | select(.format_id==\"$videoFormatID\")).protocol")

#			$debug
			remoteFileSize=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).filesize" | sed "s/null/-1/")
			$undebug
			if [ $remoteFileSize != -1 ]; then
				remoteFileSizeMiB=$(echo $remoteFileSize | awk \$1/=2^20)
			else
				filesize_approx=$(echo "$jsonHeaders" | $jq -n -r "first(inputs | select(.format_id==\"$formatID\")).filesize_approx" | sed "s/null/-1/")
				[ $filesize_approx != -1 ] && remoteFileSizeMiB=$(echo $filesize_approx | awk \$1/=2^20) || remoteFileSizeMiB=-1
			fi

			# Les resultats ci-dessous ne dependent pas du format selectionne
			isLIVE=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .is_live)'| sed "s/null/false/")
			title=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .title)' | sed "s/\xf0\x9f\x9f\xa2\s//")
			webpage_url=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .webpage_url)')
			duration=$(echo "$jsonHeaders" | $jq -n -r 'first(inputs | .duration)' | sed "s/null/0/")
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
				userAgent="$(yt-dlp --dump-user-agent)"
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
			[ -z "$thumbnailExtension" ] && thumbnailExtension=$(\curl -qLs "$thumbnailURL" | file -bi - | awk -F ';' '{sub(".*/","",$1);sub("jpeg","jpg",$1);print$1}')
			[ -n "$thumbnailExtension" ] && artworkFileName=${fileName/%.$extension/.$thumbnailExtension}

			echo $formatString | $grep -v '+' | $grep "audio only" -q && ytdlExtraOptions+=( -x ) && audioOnly=true
			if echo "${ytdlExtraOptions[@]}" | $grep -w "\-x" -q;then
				extension=$(getAudioExtension $firstAudioStreamCodecName) || continue
				( [ $extension = m4a ] || [ $extension = opus ] ) && ytdlExtraOptions+=( -k )
				newFileName="${fileName/.*/.$extension}"
			else
				newFileName="$fileName"
			fi

			echo "=> title = <$title>" && echo
			printf "=> chosenFormatID = <${effects[bold]}${colors[blue]}$chosenFormatID$normal> resolution = <${effects[bold]}${colors[blue]}$resolution$normal> "
			if [ $isLIVE == true ];then
				echo "isLIVE = <${effects[bold]}${colors[blue]}$isLIVE$normal>" && echo
				ytdlExtraOptions+=( --hls-use-mpegts --hls-prefer-ffmpeg )
				ytdlExtraOptions+=( --playlist-items 1 )
				url="$webpage_url"
			else
				echo "remoteFileSizeMiB = <$remoteFileSizeMiB MiB> duration = <$($date -u -d @$duration +%H:%M:%S)>" && echo
				ytdlExtraOptions+=( --hls-prefer-native )
			fi

			[ "$verboseLevel" = 1 ] && echo "=> acodec = <$acodec> fileName = <$fileName> extension = <$extension> isLIVE = <$isLIVE> formatString = <$formatString> thumbnailURL = <$thumbnailURL> thumbnailExtension = <$thumbnailExtension> artworkFileName = <$artworkFileName> firstAudioStreamCodecName = <$firstAudioStreamCodecName> webpage_url = <$webpage_url>" && echo

			if [ $thumbnailerName = AtomicParsley ];then
				thumbnailFormatString=$(\curl -qLs "$thumbnailURL" | file -b -)
				if echo $thumbnailFormatString | $grep -q JPEG && ! echo $thumbnailFormatString | $grep -q JFIF;then
					#Because of https://bitbucket.org/wez/atomicparsley/issues/63
					echo "${effects[bold]}${colors[blue]}=> WARNING: The remote thumbnail is not JFIF compliant, downloading it to converting it to JPEG JFIF ...$normal"
					if \curl -qLs "$thumbnailURL" -o "$artworkFileName.tmp";then
						echo "=> Converting <$artworkFileName> to JPEG JFIF for AtomicParsley ..."
						convert "$artworkFileName.tmp" "$artworkFileName" && rm -f "$artworkFileName.tmp"
						echo "=> Done."
						echo
						[ "$verboseLevel" = 1 ] && file "$artworkFileName"
						[ "$verboseLevel" = 1 ] && ls -l --time-style=+'%Y-%m-%d %T' "$artworkFileName" && echo
					fi
				fi
			fi

			echo "=> Downloading <$url> ..."
			echo

			ytdlExtraOptions+=( --add-metadata --prefer-ffmpeg --restrict-filenames )

			if [ $audioOnly = false ] && [ $isLIVE = false ];then
				ytdlExtraOptions+=( --embed-subs --write-auto-sub --sub-lang='en,fr,es,de' )
			fi


#			$undebug
			[ "$verboseLevel" = 1 ] && echo "=> ytdlExtraOptions = ${ytdlExtraOptions[@]}" && echo

			if [ -f "$newFileName" ] && [ $isLIVE != true ]; then
				echo "=> The file <$newFileName> already exists, comparing it's size with the remote file ..." 1>&2
				echo 1>&2
				fileSizeOnFS=$($stat -c %s "$newFileName" || echo 0)
				test $? != 0 && return
				if [ ! -w "$newFileName" ] || [ $fileSizeOnFS -ge $remoteFileSize ]; then
					echo "${colors[yellowOnBlue]}=> The file <$newFileName> is already downloaded and greater/equal to the remote, skipping ...$normal" 1>&2
					continue
				fi
			fi

			echo "=> fileName to be downloaded = <$fileName>"
			echo

			( [ $thumbnailerName = AtomicParsley ] || [ $thumbnailerName = ffmpeg ] ) && ( [ $extension = mp4 ] || [ $extension = m4a ] || [ $extension = m4b ] || [ $extension = mp3 ] ) && embedThumbnail="--embed-thumbnail"

			echo "=> Downloading file # $j/$numberOfFilesToDownload ..."
			echo
			printf "=> Starting $downloader at %s ...\n" "$(LC_MESSAGES=en date)"
			echo
			errorLogFile="${downloader}_errors_$$.log"
			trap - INT
			if [ $isLIVE == false ];then
#				$debug
				time videoDownloader -v --ignore-config -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
				$undebug
			else
#				$debug
				LANG=C.UTF-8 time timeout -s SIGINT $timeout $downloader -v --ignore-config -o "$fileName" -f "$chosenFormatID" "${ytdlExtraOptions[@]}" "$url" $embedThumbnail 2>$errorLogFile
				$undebug
			fi

			downloadOK=$?
			sync
			echo

			$grepColor -A1 ERROR: $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && continue || \rm $errorLogFile

			if echo "${ytdlExtraOptions[@]}" | $grep -qw -- "-x";then
				extension=$(getAudioExtension $firstAudioStreamCodecName) || continue
				fileName="${fileName/.*/.$extension}"
			fi

			fileSizeOnFS=$($stat -c %s "$fileName" || echo 0)
			if [ $fileSizeOnFS -ge $remoteFileSize ] || [ $downloadOK = 0 ]; then
				set +x
				addThumbnail2media "$fileName" "$artworkFileName"
			else
				set +x
				time videoDownloader -o $fileName -f "$chosenFormatID" "$url" 2>$errorLogFile
				downloadOK=$?
				echo

				$grepColor -A1 'ERROR:.*' $errorLogFile >&2 && echo "=> \$? = $downloadOK" >&2 && echo >&2 && return $downloadOK || \rm $errorLogFile
			fi
#			$undebug

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

	if type -P mp4tags >/dev/null 2>&1;then
		echo "[mp4tags] Adding '$url' to '$fileName' description metadata"
		time mp4tags -m "$url" "$fileName"
		retCode=$?
	elif type -P ffmpeg >/dev/null 2>&1;then
		local extension="${fileName/*./}"
		local outputVideo="${fileName/.$extension/_NEW.$extension}"

		local ffmpeg="command ffmpeg"
		local ffprobe="command ffprobe"
		ffmpeg+=" -hide_banner"
		ffprobe+=" -hide_banner"
		local jq="command jq"

		local ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
		local videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)

		if [ $videoContainer = mov ] || [ $videoContainer = mp3 ];then
			metadataURLFieldName=description
		elif [ $videoContainer = matroska ];then
			metadataURLFieldName=PURL
		fi

		echo "[ffmpeg] Adding '$url' to '$fileName' description metadata"
		movflags="+frag_keyframe"
#		$debug
		$ffmpeg -loglevel $ffmpegLogLevel -i "$fileName" -map 0 -c copy -movflags $movflags -metadata $metadataURLFieldName="$url" "$outputVideo"
		retCode=$?
		$undebug
		[ $retCode = 0 ] && sync && \mv -f "$outputVideo" "$fileName"
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

	local ffmpeg="command ffmpeg"
	ffmpeg+=" -hide_banner"

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
	local debug=""
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

	local ffmpeg="command ffmpeg"
	local ffprobe="command ffprobe"
	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"
	local jq="command jq"

	local ffmpegErrorLogLevel=repeat+error
	local ffmpegWarningLogLevel=repeat+warning
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegErrorLogLevel

	local ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
	local videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)
#	numberOfVideoStreams=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ] | length'
	local latestVideoStreamCodecName=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ][-1].codec_name')

	local major_brand=$(echo $ffprobeJSON_File_Info | $jq -r .format.tags.major_brand | sed "s/\s*$//")
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

bestFormats="bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best[ext=webm]/best[ext=avi]/best[ext=mov]/best[ext=flv]"
function getRestrictedFilenamesBEST {
	getRestrictedFilenamesFORMAT -f "($bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFHD {
	local height=1080
	local other_Formats=fhd
	local possibleFormats="bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesHD {
	local height=720
	local other_Formats=hd/high
	local possibleFormats="22/bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesHQ {
	local height=576
	local other_Formats=hq/fsd/std/sd
	local possibleFormats="bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesFSD {
	local height=480
	local other_Formats=fsd/std
	local possibleFormats="bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesSD {
	local height=360
	local other_Formats=low/sd/std
	local possibleFormats="18/bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesLD {
	local height=240
	local other_Formats=ld/low
	local possibleFormats="bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}
function getRestrictedFilenamesVLD {
	local height=144
	local other_Formats=vld/low
	local possibleFormats="bestvideo[vcodec^=avc1][height<=?$height]+bestaudio[ext=m4a]/$other_Formats/best[ext=mp4][height<=?$height]"
	getRestrictedFilenamesFORMAT -f "($possibleFormats/$bestFormats)" $@ # because of the "eval" statement in the "youtube_dl" bash variable
}

time $funcName $@
