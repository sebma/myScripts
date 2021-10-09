#!/usr/bin/env bash

function extractVideoURLsFromWebPage {
	[ $# != 0 ] && [ "$1" = "-h" ] && {
		echo "=> Usage $FUNCNAME [-t] url1 url2 url3 ..." >&2
		return 1
	}

	time for url
	do
		urlBase=$(echo "$url" | cut -d/ -f1-3)
		fqdn=$(echo "$url" | cut -d/ -f3)
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		sld=$(echo $fqdn | awk -F. '{print $(NF-1)}') # Second level domain
		echo "=> Extracting urls from <$url>..." >&2

		time if [[ "$url" =~ ^[./] ]] || [[ "$url" =~ ^[^/]+$ ]];then # If it is a local file
			localFile="$url"
			domain=$(cat "$localFile" | pup 'meta[property=og:url] attr{content}' | awk -F/ '{print$3}')
			urlPrefix=https://$domain
			case $domain in
				ok.ru)
					time extractedURLs="$(grep -oP "/video/\d+" "$localFile" | uniq | sed "s|^|$urlPrefix|")"
					i=$(echo "$extractedURLs" | wc -l)
					echo "=> Extracted $i urls from <$url>." >&2
					echo "=> Resolving titles from urls..." >&2
					echo "$extractedURLs"
				;;
				*) ;;
			esac
		elif [ $sld = dailymotion ];then
			urlPrefix=${urlBase}/video
			apiUrl="$url"
			if echo "$url" | \grep /playlist -q;then
				apiUrl="${url}/videos?limit=100"
			else
				apiUrl="$(echo "$url" | sed "s|$fqdn|$fqdn/user|" )"
			fi
			apiUrl="${apiUrl/www/api}"
			echo "=> apiUrl = $apiUrl" 1>&2
			\curl -qs "$apiUrl" | jq -r '"'$urlPrefix/'"+.list[].id'
		elif [ $sld = vimeo ];then
			urlPrefix=$urlBase
			channel="${url/*\//}"
			\curl -qs $urlBase/api/v2/$channel/videos.json | jq -r '.[] | "'$urlPrefix/'"+(.id|tostring)'
		elif [ $sld = youtube ];then
			urlPrefix=$urlBase
			\curl -qs "$url" | grep -oP '"url":"\K/watch\?v=[\d\w-_]{11}' | sort -u | sed "s|^|$urlPrefix|"
		elif [ $sld = preachub ];then
			\curl -Lqs "$url" | pup ".pm-pl-list-thumb a attr{href}"
		elif [ $domain = ok.ru ];then
			tmpFile=$(mktemp)
			\wget -qkO $tmpFile "$url"
			cat $tmpFile | grep -oP "\Khttps?://ok.ru/video/\d+" | uniq
			rm -f $tmpFile
		else
			:
		fi
	done
}

extractVideoURLsFromWebPage "$@"
