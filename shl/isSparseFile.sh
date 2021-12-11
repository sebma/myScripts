#!/usr/bin/env bash

for file
do
	if [ "$((`stat -c '%b*%B-%s' -- "$file"`))" -lt 0 ]
	then
		echo "$file" is sparse
	else
		echo "$file" is not sparse
	fi
done
