#!/usr/bin/env bash

find "$1" -type f -printf '%s %f\n' | awk '{
	e="NO_EXTENSION"
	if ($2~/\./) {e=tolower($2); sub(/^.*\./,"",e)}
	s[e]+=$1
}
END {for (e in s) print s[e],e}' |
sort -nr |
head -20 |
numfmt --to=iec
