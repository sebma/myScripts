#!/usr/bin/env -S bash -u

mp4StripEmojisFromTitle ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME mp4File1 mp4File2 mp4File3 ..." 1>&2
		return 1
	}

	local ffprobe="command ffprobe -hide_banner"
	local ffprobeJsonOutput="-v error -show_format -show_streams -of json"

	echo >&2
	echo "=> Starting $FUNCNAME $@ ..." >&2
	local emojiRegExp='[\x{1f300}-\x{1f5ff}\x{1f900}-\x{1f9ff}\x{1f600}-\x{1f64f}\x{1f680}-\x{1f6ff}\x{2600}-\x{26ff}\x{2700}-\x{27bf}\x{1f1e6}-\x{1f1ff}\x{1f191}-\x{1f251}\x{1f004}\x{1f0cf}\x{1f170}-\x{1f171}\x{1f17e}-\x{1f17f}\x{1f18e}\x{3030}\x{2b50}\x{2b55}\x{2934}-\x{2935}\x{2b05}-\x{2b07}\x{2b1b}-\x{2b1c}\x{3297}\x{3299}\x{303d}\x{00a9}\x{00ae}\x{2122}\x{23f3}\x{24c2}\x{23e9}-\x{23ef}\x{25b6}\x{23f8}-\x{23fa}\x{1f7e2}]'

	for mp4File
	do
		echo >&2
		echo "==> Processing <$mp4File> ..." >&2
		title=$(bash -c "ffprobe $ffprobeJsonOutput \"$mp4File\"" | jq -r .format.tags.title | sed "s/null//")

		test -z "$title" && echo "==> The is no title for this video, processing next file (if any) ..." >&2 && continue

		if perl -e $"use utf8; exit 0 if '$title' =~ /$emojiRegExp/; exit 1;";then
			echo "==> Emojis were found in this title: <$title>." >&2
			title=$(echo "$title" | perl -C -pe "s/\s*${emojiRegExp}\s*//g")
			echo "==> Cleaned up title = <$title>" >&2
		else
			echo "==> NO emojis were found in this title: <$title>, processing next file (if any) ..." >&2
			echo >&2
			continue
		fi

		trap 'echo "===> WARING: Do NOT try to interrupt the modification of the video or else it will be broken." >&2' INT
		timestampFileRef=$(mktemp) && touch -r "$mp4File" $timestampFileRef
		test -w "$mp4File" || chmod -v u+w "$mp4File"
		echo "==> Updating the video title without the emojis in <$mp4File> ..." >&2
		time mp4tags -s "$title" "$mp4File"
		touch -r $timestampFileRef "$mp4File" && \rm $timestampFileRef
		chmod -v -w "$mp4File"
		echo "==> DONE processing $mp4File." >&2
		trap - INT
	done
	echo "=> Finished !" >&2
}

mp4StripEmojisFromTitle "$@"
