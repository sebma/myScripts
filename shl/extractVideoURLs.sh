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
			\curl -qs "${url/www/api}/videos" | jq -r '"'$urlPrefix/'"+.list[].id'
		elif [ $sld = vimeo ];then
			urlPrefix=$urlBase
			channel="${url/*\//}"
			\curl -qs $urlBase/api/v2/$channel/videos.json | jq -r '.[] | "'$urlPrefix/'"+(.id|tostring)'
		else
			urlPrefix=$urlBase
			\curl -qs "$url" | grep -w video | grep -oP 'href="\K/[^/][^ &"]+' | uniq | sed "s|^|$urlPrefix|"
		fi
	done
}

extractVideoURLs "$@"
