#!/usr/bin/env bash

for url
do
	fqdn=$(echo $url | cut -d/ -f1-3)
	domain=$(echo $fqdn | awk -F '[.]|/' '{print $(NF-1)}')
	\curl -qs $url | grep -oP 'video\b.*href="\K/[^/][^ &"]+' | uniq | sed "s|^|$fqdn|"
done
