#!/usr/bin/env bash

[ $# = 0 ] || [ $1 = -h ] && {
	echo "=> Usage ${0/*\//} url1 url2 ..." >&2
	exit 1
}

peterAdamJPV_BaseURL=http://www.peter-adam.com/jpv
for url
do
	if echo "$url" | grep -q $peterAdamJPV_BaseURL/viewitem.php;then
		videoTitlePrefix="$(\curl -qLs "$url" | pup 'meta[property=og:title] attr{content}' | awk '{print$1" "$2" - "$3}')"
		videoTitle="$(\curl -qLs "$url" | pup 'span span[style="font-weight:bold; "] text{}' | sed "s/&#39;/'/g")"
		videoTitle="$videoTitlePrefix - $videoTitle"
		videoID=$(\curl -qLs "$url" | pup 'meta[property=og:description] attr{content}' | awk -F'[[ ]' '{print$2}')
		videoFileName="$(echo $videoTitle | sed 's/ /_/g')__peter-adam_com.mp4"
echo "=> videoFileName = $videoFileName"
		set -x
#		youtube-dl --ignore-config -co "$videoFileName" $peterAdamJPV_BaseURL/pop/popJW.php?nc=$videoID && chmod -w "$videoFileName"
		set +x
	else
		echo "=> Only <$peterAdamJPV_BaseURL/viewitem.php> url types are supported." >&2
		continue
	fi
done
