#!/usr/bin/env sh

#grep -v EXTM3U "$@" | awk -F"," '/EXTINF/{$1="";title=$0}/^(https?|s?ftps?|ssh):/{url=$0;print url" #"title}'
tail -n +2 "$@" | tac | \sed -E 'N;s/\n#EXTINF:-1,/ # /' | tac
