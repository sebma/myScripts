#!/usr/bin/env bash

function mpvSD { 
    local formats="18 webm sd http-480 best"
    local formatsRegExp=$(echo $formats | sed "s/ /|/g")
    for url in "$@"
    do
        format=$($(which youtube-dl) -F $url | awk "/$formatsRegExp/"'{exit}END{print $1}')
        $(which mpv) --ytdl-format $format $url
    done
}

mpvSD $@
