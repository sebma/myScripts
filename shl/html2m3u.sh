#!/usr/bin/env bash

multiMediaFormats="\\.(wav|wma|aac|ac3|mp2|mp3|ogg|oga|ogm|m4a|m4b|spx|opus|asf|avi|wmv|mpg|mpeg|mp4|divx|flv|mov|ogv|webm|vob|3gp|mkv|m2t|mts|m2ts|asx|m3u|m3u8|pla|pls|smil|vlc|wpl|xspf)"

mainURL="$1"

echo "#EXTM3U"
hxwls "$mainURL" | egrep $multiMediaFormats | uniq | while read url
do
	printf "#EXTINF:-1,"
	echo $(basename "$url") | sed -r 's/(\.[a-z]{3}).*$/\1/'
	echo "$url" | sed "/dropbox.com/s/dl=0$/dl=1/"
done
