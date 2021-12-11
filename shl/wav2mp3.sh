#!/usr/bin/env bash

echo ${0##*/} && return 0

test $# -eq 0 && fileList="*.wav *.WAV *.mp2 *.MP2"
test "$fileList" && for file in $fileList
do
  extension=`echo "$file" | cut -d. -f2`
  lame -v "$file" "${file%.$extension}.mp3" && rm -v "$file"
done || for file
do
  extension=`echo "$file" | cut -d. -f2`
  lame -v "$file" "${file%.$extension}.mp3" && rm -v "$file"
done
