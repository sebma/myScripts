#!/usr/bin/env sh

grep -v EXTM3U $@ | awk -F"," '/EXTINF/{title=$2}/^(https?|s?ftps?|ssh):/{print $0" # "title}'
