#!/usr/bin/env bash

function getURLTitle() {
	if type -P xidel > /dev/null; then
		for URL
		do
			printf "$URL # "
			xidel -s --css 'head title' "$URL"
		done
	elif type -P pup > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs "$URL" | pup --charset utf8 'head title text{}'
		done
	elif type -P hxselect > /dev/null; then
		for URL
		do
			printf "$URL # "
			\curl -qLs "$URL" | hxnormalize -x | hxselect -s '\n' 'head title' -c
		done
	else
		if \grep -P '.*' <<< 'Test' >/dev/null;then
			for URL
			do
				\curl -qLs "$URL" | \grep -oP '<title>\K[^<]*'
			done
		else
			for URL
			do
				\curl -qLs "$URL" | \perl -le '$/=undef; $s=<>; $s =~ m{<title>(.*)</title>}si; print $1 if $1'
			done
		fi
	fi
}

getURLTitle $@
