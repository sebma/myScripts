#!/usr/bin/env bash

any2mp4Fonction() {
	local codeRet=0

	if type ffmpeg >/dev/null
	then
		videoConv=$(which ffmpeg)
	else
		echo "=> ERROR: <ffmpeg> is not installed." >&2
		return 1
	fi

	for file
	do
		echo "=> file = $file"
		if $videoConv -i "$file" 2>&1 | egrep "Stream .*Video.*(h264)"
		then
				 outPutFile="${file%.???}.mp4"
				 if $videoConv -i "$file" 2>&1 | egrep -q "^Input #[0-9], flv,"
				 then
					 freeSpace=$(\df -Pk "$file" | awk '/dev|tmpfs/{print int($4)}')
					 fileSize=$(\ls -l "$file" | awk '{print int($5/1024)}')

					 if [ $freeSpace -lt $fileSize ]
					 then
						 \mv -v "$file" /tmp
						 fileBaseName=$(basename "$file")
						 $videoConv -i "/tmp/$fileBaseName" -f mp4 -vcodec copy -acodec copy -movflags frag_keyframe "$outPutFile" && \rm -v "/tmp/$fileBaseName" || break
					 else
						 $videoConv -i "$file" -f mp4 -vcodec copy -acodec copy -movflags frag_keyframe "$outPutFile" || break
						 \rm -v "$file"
					 fi
				 else
					 \mv -v "$file" "$outPutFile"
				 fi
		else
			echo "==> No h264 stream to copy was found." 2>&1
		fi
		echo
	done
	return
}

any2mp4Fonction "$@"
