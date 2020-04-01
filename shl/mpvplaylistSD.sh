#!/usr/bin/env bash

test $# != 0 && rm -f nohup.out && nohup mpv --ytdl-format='best[height<=480]/mp4/best' --ytdl-raw-options=abort-on-error= --playlist $1 &
test $# != 0 && tail -f nohup.out
