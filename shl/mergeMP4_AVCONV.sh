#!/usr/bin/env bash

#time -p avconv -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -c copy output.mp4
#time -p avconv -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -map 0 -c copy output.mp4
#time -p ffmpeg -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $(ls -v $@)) -scodec copy -c:a copy -c:v copy output.mp4
fileList=$(ls -v $@)

#for file in $fileList
#do
#	ffmpeg -probesize 400M -analyzeduration 400M -i $file -bsf h264_mp4toannexb -c copy -f mpegts ${file/mp4/ts} -y
#done
#newFileList=$(echo $fileList | sed "s/.mp4 /.ts /g")
#set -x
#time -p ffmpeg -probesize 400M -analyzeduration 400M -i concat:$(printf "%s|" $newFileList) -bsf:a aac_adtstoasc -c:a copy -c:v copy output.mp4 -y
#time -p ffmpeg -hide_banner -f concat -probesize 400M -analyzeduration 400M -i <(printf "file %s\n" $(ls -v $@)) -bsf:a aac_adtstoasc -c copy output.mp4 -y
cat <(printf "file %s\n" $(ls -v $@)) > toto.txt
time -p ffmpeg -hide_banner -f concat -probesize 400M -analyzeduration 400M -i toto.txt -bsf:a aac_adtstoasc -c copy output.mp4 -y
remux.sh output.mp4 output2.mp4
mv -v output2.mp4 output.mp4
rm toto.txt
