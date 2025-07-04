#!/usr/bin/env -S bash -u

videoRemuxFromVCodec ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME mp4File1 mp4File2 mp4File3 ..." 1>&2
		return 1
	}

	local ffprobe="command ffprobe -hide_banner"
    local ffprobeJsonOutput="-v error -show_format -show_streams -of json"
	local remuxOptions="-map 0 -c copy"
	local mp4Options="-movflags +frag_keyframe"
	local ffmpeg="command  ffmpeg  -hide_banner"

	echo >&2
	echo "=> Starting $FUNCNAME $@ ..." >&2

	for videoFile
	do
		echo >&2
		echo "==> Processing <$videoFile> ..." >&2
		extension="${videoFile/*./}"
		echo "==> extension = <$extension>" >&2

		vcodec_name=$(bash -c "ffprobe $ffprobeJsonOutput \"$videoFile\"" | jq -r .streams[0].codec_name | sed "s/null//")
		test -z "$vcodec_name" && echo "==> The is no vcodec_name for this video, processing next file (if any) ..." >&2 && continue

		echo "==> vcodec_name = <$vcodec_name>" >&2
		case $vcodec_name in
			h264) newExtension=mp4;;
			*) echo "==> This format is not supported yet." >&2; continue;;
		esac
		echo "==> newExtension = <$newExtension>" >&2

 		[ $newExtension = mp4 ] && remuxOptions="$remuxOptions $mp4Options"

		if [ $newExtension != $extension ];then
			outputFile="${videoFile/$extension/$newExtension}"
			echo "==> Remuxing the video according to its vcodec_name which is <$vcodec_name>." >&2
			time $ffmpeg -i "$videoFile" $remuxOptions "$outputFile"
			sync
			touch -r "$videoFile" "$outputFile"
		 	echo "==> outputFile = <$outputFile>" >&2
			echo "==> DONE processing $videoFile." >&2
		fi
	done
	echo "=> Finished !" >&2
}

videoRemuxFromVCodec "$@"
