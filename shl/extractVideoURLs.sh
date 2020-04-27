#!/usr/bin/env bash

function extractVideoURLs {
	for url
	do
		urlBase=$(echo "$url" | cut -d/ -f1-3)
		fqdn=$(echo "$url" | cut -d/ -f3 | awk -F. '{print$(NF-1)"."$NF}')
		domain=$(echo $fqdn | awk -F. '{print $(NF-1)}')
		\curl -qs $url | grep -w video | grep -oP 'href="\K/[^/][^ &"]+' | uniq | sed "s|^|$urlBase|"
	done
}

extractVideoURLs "$@"
