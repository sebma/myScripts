#!/usr/bin/env bash

function getURLTitle() {
	if type -P htmlq > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs "$URL" | htmlq -t 'title' | \xargs
		done
	elif type -P pup > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs "$URL" | pup --charset utf8 'head title text{}' | \xargs
		done
	elif type -P hxselect > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs "$URL" | hxnormalize -x | hxselect -s '\n' 'head title' -c | \xargs
		done
	elif type -P xidel > /dev/null; then
		for URL
		do
			printf "$URL # "
			xidel -s --css 'head title' "$URL" | \xargs
		done
	else
		if type -P gawk > /dev/null; then
			for URL
			do
				printf "$URL # "
				\curl -qLs "$URL" | \gawk -v IGNORECASE=1 -v RS='</title' 'RT{gsub(/.*<title[^>]*>/,"");print;exit}' | \xargs
			done
		elif type -P perl > /dev/null; then
			for URL
			do
				printf "$URL # "
				\curl -qLs "$URL" | \perl -le '$/=undef; $s=<>; $s =~ m{<title>(.*)</title>}si; print $1 if $1'| \xargs
			done
		elif type -P grep > /dev/null && \grep -P '.*' -q <<< 'Test' 2> /dev/null;then
			for URL
			do
				printf "$URL # "
				\curl -qLs "$URL" | \grep -oP '<title>\K[^<]*' || \curl -qLs "$URL" | \grep -iPo '(?<=<title>)(.*)(?=</title>)'
			done
		else
			for URL
			do
				printf "$URL # "
				\curl -qLs "$URL" |	grep -o "<title>[^<]*" | cut -d'>' -f2-
			done
		fi
	fi
}

getURLTitle $@
