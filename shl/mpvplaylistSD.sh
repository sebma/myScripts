#!/usr/bin/env bash

test $# != 0 && LANG=en_US.utf8 nohup mpv --ytdl-format="best[height<=480]/mp4/best" --ytdl-raw-options=abort-on-error= --playlist=$1 &
test $# != 0 && touch nohup.out && tail -f nohup.out
