#!/usr/bin/env bash

scriptBaseName=${0##*/}
test $# != 1 && {
	echo "=> Usage $scriptBaseName ok_ru_htmlFile" >&2
	exit 1
}
ok_ru_htmlFile=$1
cat $ok_ru_htmlFile | pup 'json{}' | jq -r 'recurse | arrays[] | select(.class == "video-card_n ellip").title,select(.class == "video-card_lk").href' | awk '{id = $0;url="https://ok.ru"gensub("?.*$","",id); getline title; print url" # "title}'
