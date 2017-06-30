#!/usr/bin/env bash

for file
do
	avprobe $file 2>&1 | egrep --color -i "input|kb/s"
	mediainfo $file | egrep --color -i "name|bit.rate"
done
