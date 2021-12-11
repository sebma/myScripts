#!/usr/bin/env bash

sortM3U () {
	local sort="command sort"
	for file in "$@"
	do
		( echo "#EXTM3U";grep --color -v "#EXTM3U" "$file" | paste - - | $sort -V | \sed "s/\t/\n/" )
	done
}

sortM3U "$@"
