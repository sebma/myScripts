#!/usr/bin/env bash

for file
do
	test "$(tail -c 1 "$file" | wc -l)" = 0 && echo "=> no newline at eof: $file"
done
