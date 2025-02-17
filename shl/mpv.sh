#!/usr/bin/env bash

mpv=$(which mpv)
cd ~/Pictures || cd
#HOSTNAME=$(hostname) nohup $mpv "$@" &
HOSTNAME=$HOSTNAME nohup $mpv "$@" &
