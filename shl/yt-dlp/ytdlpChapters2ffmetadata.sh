#!/usr/bin/env bash

function ytdlpChapters2ffmetadata {
	for jsonFile
	do
		jq -r '
";FFMETADATA1" ,
.chapters[]? as $c | "[CHAPTER]" ,
"TIMEBASE=1/1000" ,
"START=" + ($c.start_time * 1000 | floor | tostring) ,
"END="   + ($c.end_time   * 1000 | floor | tostring) ,
"title=" + $c.title // ""
' "$jsonFile" > "${jsonFile/.json/.ffmeta}"
		ls -l "${jsonFile/.json}"*
	done
}

ytdlpChapters2ffmetadata "$@"
