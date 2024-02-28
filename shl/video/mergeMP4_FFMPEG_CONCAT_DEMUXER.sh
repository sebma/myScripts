#!/usr/bin/env bash


#time -p ffmpeg -hide_banner -f concat -i <(printf "file %s\n" $(ls -v $@)) -c copy output.mp4 -y
printf "file %s\n" $(ls -v $@) > toto1.txt
time -p ffmpeg -hide_banner -f concat -i toto1.txt -c copy output1.mp4 -y
remux.sh output1.mp4 output2.mp4
mv -v output2.mp4 output1.mp4
rm toto1.txt
sync
