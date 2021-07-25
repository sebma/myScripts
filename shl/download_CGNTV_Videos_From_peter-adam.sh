#!/usr/bin/env bash

[ $# = 0 ] || [ $1 = -h ] && {
	echo "=> Usage ${0/*\//} url1 url2 ..." >&2
	exit 1
}

for url
do
	if echo "$url" | grep -q www.peter-adam.com/jpv/viewitem.php;then
		videoTitle=$(\curl -qLs "$url" | pup 'head title text{}' | cut -d- -f2- | sed 's/^ *//;s/#//')
		videoFileName=$(echo $videoTitle | sed 's/ /_/g').mp4
		videoID=$(\curl -qLs "$url" | pup 'meta[property=og:description] attr{content}' | awk -F'[[ ]' '{print$2}')
		videoDirectURL=$(youtube-dl --ignore-config --no-warnings -g http://www.peter-adam.com/jpv/pop/popJW.php?nc=$videoID)
		set -x
		wget -cO "$videoFileName" "$videoDirectURL"
		set +x
	else
		echo "=> Only <www.peter-adam.com/jpv/viewitem.php> url types are supported." >&2
		continue
	fi
done
