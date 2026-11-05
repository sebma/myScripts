#!/usr/bin/env bash

awk '!/^WEBVTT/ && !/^NOTE/ && !/^STYLE/ && !/^REGION/ && !/-->/ && !/^[0-9]+$/ && NF { gsub(/<[^>]*>/, ""); print }' $1 | uniq > ${1/.vtt/-awk.txt}
perl -ne 'next if /^(WEBVTT|NOTE|STYLE|REGION)/ || /-->/ || /^\s*\d+\s*$/ || /^\s*$/; s/<[^>]*>//g; print' $1 | uniq > ${1/.vtt/-perl.txt}
