#!/usr/bin/env bash

function yt-dlpChapters2ffmetadata {
	for jsonFile
	do
		jq -r '
";FFMETADATA1",
.chapters[]? as $c
| "[CHAPTER]\n"
+ "TIMEBASE=1/1000\n"
+ "START=" + (($c.start_time * 1000 | floor) | tostring) + "\n"
+ "END="   + (($c.end_time   * 1000 | floor) | tostring) + "\n"
+ "title=" + ($c.title // "")
' "$jsonFile" > "${jsonFile/.json/.ffmeta}"
		ls -l "${jsonFile/.json}"*
	done
}

yt-dlpChapters2ffmetadata "$@"
