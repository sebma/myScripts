#!/usr/bin/env -S bash -u -e

mp4StripEmojisFromTitle ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME mp4File1 mp4File2 mp4File3 ..." 1>&2
		return 1
	}

	local ffprobe="command ffprobe -hide_banner"

	echo "=> Starting $FUNCNAME $@ ..." >&2
	local emojiRegExp='[\x{1f300}-\x{1f5ff}\x{1f900}-\x{1f9ff}\x{1f600}-\x{1f64f}\x{1f680}-\x{1f6ff}\x{2600}-\x{26ff}\x{2700}-\x{27bf}\x{1f1e6}-\x{1f1ff}\x{1f191}-\x{1f251}\x{1f004}\x{1f0cf}\x{1f170}-\x{1f171}\x{1f17e}-\x{1f17f}\x{1f18e}\x{3030}\x{2b50}\x{2b55}\x{2934}-\x{2935}\x{2b05}-\x{2b07}\x{2b1b}-\x{2b1c}\x{3297}\x{3299}\x{303d}\x{00a9}\x{00ae}\x{2122}\x{23f3}\x{24c2}\x{23e9}-\x{23ef}\x{25b6}\x{23f8}-\x{23fa}\x{1f7e2}]'

	for mp4File in "$@"
	do
		echo "==> Processing $mp4File ..." >&2
		set -o pipefail
		title=$(bash -c "time ffprobe -v error -show_format -show_streams -of json \"$mp4File\"" | jq -r .format.tags.title | sed "s/null//") || exit
		set +o pipefail

		echo "==> title = <$title>"
		test -z "$title" && exit

		if perl -e "use utf8; exit 0 if '$title' =~ /$emojiRegExp/; exit 1;";then
			echo "=> Emojis were found in <$title>." >&2
			title=$(echo "$title" | perl -C -pe "s/${emojiRegExp}\s*//g")
			echo "==> title = <$title>" >&2
		else
			echo "==> NO emojis were found in <$title>, processing next file (if any) ..." >&2
			echo >&2
			continue
		fi

		timestampFileRef=$(mktemp) && touch -r "$mp4File" $timestampFileRef
		test -w "$mp4File" || chmod -v u+w "$mp4File"
		echo "==> Removing the emojis present in the title of <$mp4File> ..." >&2
		time mp4tags -s "$title" "$mp4File"
		touch -r $timestampFileRef "$mp4File" && \rm $timestampFileRef
		chmod -v -w "$mp4File"
		echo "==> Processing $mp4File is Done." >&2
	done
	echo "=> Finished !" >&2
}

mp4StripEmojisFromTitle "$@"
