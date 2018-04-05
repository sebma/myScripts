#!/bin/sh

Ratio="33%"
declare -i Factor=1/3
declare -i Quality=30
[ ! -d ~/Desktop/SmallPics ] && mkdir ~/Desktop/SmallPics

time for big_pic in "~/Desktop/*.JPG"
do
	FileName="$(basename $big_pic .JPG).small.jpg"
	convert -resize $Ratio -quality $Quality "$big_pic" "~/Desktop/SmallPics/$FileName"
	jhead -ft "~/Desktop/SmallPics/$FileName"
	#djpeg -scale $Factor "$big_pic" | cjpeg -quality $Quality "~/Desktop/SmallPics/$FileName"
done
