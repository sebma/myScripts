#!/usr/bin/env bash

scriptBaseName=${0##*/}
test $# != 1 && {
	echo "=> Usage $scriptBaseName ok_ru_htmlFile" >&2
	exit 1
}

ok_ru_htmlFile=$1
urlBase="https://ok.ru"
#nbsp="\xC2\xA0" # https://en.wikipedia.org/wiki/Non-breaking_space
nbspUnicodeCodePoint='"\u00A0"' # https://en.wikipedia.org/wiki/Non-breaking_space
cat $ok_ru_htmlFile | pup 'json{}' | nbspUnicodeCodePoint=$nbspUnicodeCodePoint jq -r 'recurse | arrays[] | ( select(.class == "video-card_n ellip").title | gsub("\n";" ") | gsub(env.nbspUnicodeCodePoint | fromjson;" ") ),( select(.class == "video-card_lk").href | sub("[?].*$";"") )' | awk '{url=$0;getline title;print url" # "title}'
