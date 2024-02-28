#!/usr/bin/env bash

for file
do
	ffmpeg -i $file -bsf h264_mp4toannexb -c copy -f mpegts ${file/.???/.ts} -y
done

fileList=$(ls -v $@)
newFileList=$(echo $fileList | sed "s/\.m../.ts/g")
time -p ffmpeg -hide_banner -i concat:$(printf "%s|" $newFileList) -c copy -bsf:a aac_adtstoasc output.mp4 -y
rm *.ts
sync
