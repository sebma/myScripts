#!/usr/bin/env bash

[ "$1" ] || { echo "You forgot search string!" ; exit 1 ; }
find .  -type f -and '(' -name "*.od?" -or -name "*.docx" -or -name "*.xlsx" ')' | while read file ; do
	 unzip -ca "$file" 2>/dev/null | grep -P --label="$file" "$@"
done
