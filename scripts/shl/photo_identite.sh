#!/bin/sh

Ratio="9%"
declare -i Quality=80

big_pic="$1"
FileName="$(basename $big_pic .jpg).small.jpg"
convert -resize $Ratio -quality $Quality "$big_pic" "$FileName"
jhead -ft "$FileName"
#convert -resize $Ratio "$big_pic" "$FileName"
