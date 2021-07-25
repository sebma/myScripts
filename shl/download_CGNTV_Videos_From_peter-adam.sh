#!/usr/bin/env bash

[ $# = 0 ] || [ $1 = -h ] && {
	echo "=> Usage ${0/*\//} url1 url2 ..." >&2
	exit 1
}

peterAdamJPV_BaseURL=http://www.peter-adam.com/jpv
for url
do
	if echo "$url" | grep -q $peterAdamJPV_BaseURL/viewitem.php;then
		videoTitle=$(\curl -qLs "$url" | pup 'meta[property=og:title] attr{content}')
		videoFileName=$(echo $videoTitle | sed 's/ /_/g').mp4
		videoID=$(\curl -qLs "$url" | pup 'meta[property=og:description] attr{content}' | awk -F'[[ ]' '{print$2}')
		set -x
		youtube-dl --ignore-config -co "$videoFileName" $peterAdamJPV_BaseURL/pop/popJW.php?nc=$videoID
		set +x
	else
		echo "=> Only <$peterAdamJPV_BaseURL/viewitem.php> url types are supported." >&2
		continue
	fi
done
