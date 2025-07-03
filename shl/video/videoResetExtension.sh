#!/usr/bin/env -S bash -u

videoResetExtension ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME mp4File1 mp4File2 mp4File3 ..." 1>&2
		return 1
	}

	local ffprobe="command ffprobe -hide_banner"
    local ffprobeJsonOutput="-v error -show_format -show_streams -of json"

	echo >&2
	echo "=> Starting $FUNCNAME $@ ..." >&2

	for videoFile
	do
		echo >&2
		echo "==> Processing <$videoFile> ..." >&2
		format_name=$(bash -c "ffprobe $ffprobeJsonOutput \"$videoFile\"" | jq -r .format.format_name | sed "s/null//")

		test -z "$format_name" && echo "==> The is no format_name for this video, processing next file (if any) ..." >&2 && continue

		echo "==> format_name = <$format_name>"
		case $format_name in
			"mov,mp4,m4a,3gp,3g2,mj2") newExtension=mp4;;
			mpegts) newExtension=m2ts;;
			*) echo "==> This format is not supported yet." >&2; continue;;
		esac
		echo "==> newExtension = <$newExtension>"

		extension="${videoFile/*./}"
		echo "==> extension = <$extension>"

		if [ $newExtension != $extension ];then
			echo "==> Renamming the video according to its format_name which is <$format_name>." >&2
			mv -v "$videoFile" "${videoFile/$extension/$newExtension}"
			echo "==> DONE processing $videoFile." >&2
		fi
	done
	echo "=> Finished !" >&2
}

videoResetExtension "$@"
