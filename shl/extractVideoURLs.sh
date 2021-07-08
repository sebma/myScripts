#!/usr/bin/env bash

function extractVideoURLs {
	for url
	do
		urlBase=$(echo "$url" | cut -d/ -f1-3)
		fqdn=$(echo "$url" | cut -d/ -f3)
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		sld=$(echo $fqdn | awk -F. '{print $(NF-1)}') # Second level domain
		if [ $sld = dailymotion ];then
			urlPrefix=${urlBase}/video
			apiUrl="$url"
			echo "$url" | \grep -q /playlist || apiUrl="$(echo "$url" | sed "s|$fqdn|$fqdn/user|" )"
			apiUrl="${apiUrl/www/api}"
			echo "$url" | \grep -q /videos$ || apiUrl="$apiUrl/videos"
			echo "=> apiUrl = $apiUrl" 1>&2
			\curl -qs "$apiUrl" | jq -r '"'$urlPrefix/'"+.list[].id'
		elif [ $sld = vimeo ];then
			urlPrefix=$urlBase
			channel="${url/*\//}"
			\curl -qs $urlBase/api/v2/$channel/videos.json | jq -r '.[] | "'$urlPrefix/'"+(.id|tostring)'
		elif [ $sld = youtube ];then
			urlPrefix=$urlBase
			\curl -qs "$url" | grep -w video | grep -oP 'href="\K/[^/][^ &"]+' | uniq | sed "s|^|$urlPrefix|"
		elif [ $domain = ok.ru ];then
			tmpFile=$(mktemp)
			\wget -qkO $tmpFile "$url"
			cat $tmpFile | grep -oP "\Khttps?://ok.ru/video/\d+" | uniq
			rm -f $tmpFile
		else
			:
		fi | while read videoHtmlURL
		do
			printf "$videoHtmlURL # "
			\curl -Ls "$videoHtmlURL" | pup --charset utf8 'title text{}'
		done | \recode html..latin9
	done
}

extractVideoURLs "$@"
