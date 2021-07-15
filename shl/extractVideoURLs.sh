#!/usr/bin/env bash

function extractVideoURLs {
	local tmpFile=$(mktemp)
	local displayTitles=false

	[ $# != 0 ] && [ "$1" = "-h" ] && {
		echo "=> Usage $FUNCNAME [-t] url1 url2 url3 ..." >&2
		return 1
	}

	[ $# != 0 ] && [ "$1" = "-t" ] && shift && displayTitles=true

	for url
	do
		urlBase=$(echo "$url" | cut -d/ -f1-3)
		fqdn=$(echo "$url" | cut -d/ -f3)
		domain=$(echo $fqdn | awk -F. '{print$(NF-1)"."$NF}')
		sld=$(echo $fqdn | awk -F. '{print $(NF-1)}') # Second level domain
		echo "=> Counting urls from <$url>..." >&2
		echo "=> Done." >&2

		time if [[ "$url" =~ ^[./] ]] || [[ "$url" =~ ^[^/]+$ ]];then # If it is a local file
			localFile="$url"
			domain=ok.ru # A AUTOMATISER
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
		elif [ $sld = preachub ];then
			\curl -Lqs "$url" | pup ".pm-pl-list-thumb a attr{href}"
		elif [ $domain = ok.ru ];then
			tmpFile=$(mktemp)
			\wget -qkO $tmpFile "$url"
			cat $tmpFile | grep -oP "\Khttps?://ok.ru/video/\d+" | uniq
			rm -f $tmpFile
		else
			:
		fi > $tmpFile

		if ! $displayTitles;then
			cat $tmpFile
		else
			cat $tmpFile | while read videoHtmlURL
			do
				printf "$videoHtmlURL # "
				if which xidel> /dev/null; then
					xidel -s -e //title "$videoHtmlURL"
				elif which pup> /dev/null; then
					\curl -qLs "$videoHtmlURL" | pup --charset utf8 'title text{}'
				fi
			done
#			echo >&2;echo "=> DONE: Extracted $i urls from $url." >&2
		fi
	done
}

time extractVideoURLs "$@"
