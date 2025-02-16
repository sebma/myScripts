#!/usr/bin/env bash

mpv=$(which mpv)
#HOSTNAME=$(hostname) nohup $mpv "$@" &
HOSTNAME=$HOSTNAME nohup $mpv "$@" &
