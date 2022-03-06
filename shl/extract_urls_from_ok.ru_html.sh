#!/usr/bin/env bash

scriptBaseName=${0##*/}
test $# != 1 && {
	echo "=> Usage $scriptBaseName ok_ru_htmlFile" >&2
	exit 1
}

ok_ru_htmlFile=$1
urlBase="https://ok.ru"
cat $ok_ru_htmlFile | pup 'json{}' | jq -r 'recurse | arrays[] | select(.class == "video-card_n ellip").title,select(.class == "video-card_lk").href' | awk '{videoRelativeURL=$0;sub("?.*$","",videoRelativeURL);url=videoRelativeURL; getline title; print url" # "title}'
