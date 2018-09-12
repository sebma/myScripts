#!/usr/bin/env bash

nohup nohup mpv --ytdl-format 'best[height<=480]' --playlist $1 &
tail -f nohup.out
