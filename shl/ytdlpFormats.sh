#!/usr/bin/env sh

ytdlpFormats ()
{
	trap 'rc=130;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;return $rc' INT
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME [--filterFormats] url1 url2 ..." 1>&2
		return 1
	}
	local filterFormats="."
	echo $1 | \grep -q -- "^--" && {
		filterFormats=${1:2}
		shift
	}
	time yt-dlp -F "$@" | egrep --color=auto -vw "information|manifest|android player|automatic captions|Available formats|Checking .* video format URL" | \egrep "$filterFormats|Downloading|format code  extension  resolution note"
	trap - INT
}

ytdlpFormats "$@"
