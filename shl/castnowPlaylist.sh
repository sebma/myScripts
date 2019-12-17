#!/usr/bin/env sh

castnowURLs ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME [ytdl-format] url1 url2 ..." 1>&2
		return 1
	}
	local format="mp4[height<=480]/mp4/best"
	echo $1 | \egrep -q "^(https?|s?ftps?)://" || {
		format="$1"
		shift
	}
	for url in "$@"
	do
		echo "youtube-dl --no-continue --ignore-config -f $format -o- -- $url | castnow --quiet -"
		LANG=C.UTF-8 command youtube-dl --no-continue --ignore-config -f "$format" -o- -- "$url" | castnow --quiet -
	done
	set +x
	echo
}

castnowPlaylist ()
{
	test $# = 0 && {
		echo "=> Usage: $FUNCNAME [index] [format] playlistFile ..." 1>&2
		return 1
	}
	local index=1
	local format="mp4[height<=480]/mp4/best"
	local playlist
	test $# = 1 && playlist=$1
	test $# = 2 && format=$1 && playlist=$2
	test $# = 3 && index=$1 && format=$2 && playlist=$3
	printf "=> Start playing playlist at: "
	\sed -n "${index}p" $playlist
	castnowURLs $format $(awk '{print$1}' $playlist | \grep -v "^#" | tail -n +$index)
}

castnowPlaylist "$@"
