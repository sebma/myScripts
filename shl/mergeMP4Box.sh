#!/usr/bin/env sh

#time -p MP4Box -force-cat $(printf " -cat %s" $(ls -v $@)) -new output.mp4
set -x
time -p MP4Box -force-cat $(printf " -cat %s#audio" $(ls -v $@)) -new audio_output.mp4 
#time -p MP4Box -force-cat $(printf " -cat %s#TrackID=2" $(ls -v $@)) -new audio_output.mp4 
##time -p MP4Box $(printf " -cat %s#TrackID=2" $(ls -v $@)) -new audio_output.mp4 
time -p MP4Box -force-cat $(printf " -cat %s#video" $(ls -v $@)) -new video_output.mp4 
time -p MP4Box -add video_output.mp4 -add audio_output.mp4 output.mp4
#rm audio_output.mp4 video_output.mp4
