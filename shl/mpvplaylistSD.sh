#!/usr/bin/env bash

nohup nohup mpv --ytdl-format 'best[height<=480]/mp4/best' --ytdl-raw-options=abort-on-error= --playlist $1 &
tail -f nohup.out
