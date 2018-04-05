#!/usr/bin/env bash

function YTRename {
	for file
	do
		echo "=> file = $file"
		grep -q __ <<< $file || continue
		id=$(awk -F"__" '{sub("[.]....?$","");print$NF}' <<< $file)
		format=$(awk -F__ '{print$(NF-1)}' <<< $file)
		newName="$(youtube-dl -f "$format" --get-filename -- $id)"
		test $newName || continue
		test "$(basename $file)" != "$newName" && mv -v "$file" "$(dirname $file)/$newName"
	done
}

YTRename $@
