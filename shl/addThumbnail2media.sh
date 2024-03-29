#!/usr/bin/env bash

addThumbnail2media() {
	local scriptOptions=null
	echo $1 | \grep -q -- "^-[a-z]" && scriptOptions=$1 && shift

	if [ $# != 2 ];then
		echo "=> Usage: $FUNCNAME [-v] artworkFile mediaFile" 1>&2
		exit 1
	fi

	echo $scriptOptions | \grep -q -- "-v" && debug="set -x"
	local artworkFileName="$1"
	local fileName="$2"

	local ffmpeg="command ffmpeg"
	local ffprobe="command ffprobe"
	local jq="command jq"

	ffmpeg+=" -hide_banner"
	ffprobe+=" -hide_banner"

	local ffmpegNormalLogLevel=repeat+error
	local ffmpegInfoLogLevel=repeat+info
	local ffmpegLogLevel=$ffmpegNormalLogLevel

	local ffprobeJSON_File_Info=$($ffprobe -v error -show_format -show_streams -print_format json "$fileName")
#	numberOfVideoStreams=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ] | length'
	local latestVideoStreamCodecName=$(echo $ffprobeJSON_File_Info | $jq -r '[ .streams[] | select(.codec_type=="video") ][-1].codec_name')

	local videoContainer=$(echo $ffprobeJSON_File_Info | $jq -r .format.format_name | cut -d, -f1)
	local major_brand=$(echo $ffprobeJSON_File_Info | $jq -r .format.tags.major_brand)

	[ "$debug" ] && echo "=> videoContainer = <$videoContainer>  latestVideoStreamCodecName = <$latestVideoStreamCodecName> major_brand = <$major_brand>" && echo

	if [ -s "$artworkFileName" ] && [ "$latestVideoStreamCodecName" != mjpeg ] && [ "$latestVideoStreamCodecName" != png ];then
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
			mimetype=$(file -bi "$artworkFileName" | cut -d';' -f1)
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
		chmod -w "$fileName"
	fi
}

addThumbnail2media "$@"
