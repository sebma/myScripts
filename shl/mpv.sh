#!/usr/bin/env bash

mpv=$(which mpv)
logDIR=$HOME/log/mpv
timestamp=$(date +%Y%m%d-%HH%M)
mkdir -pv $logDIR/
#HOSTNAME=$(hostname) nohup $mpv "$@" >$logDIR/mpv-$timestamp.log 2>&1 &
HOSTNAME=$HOSTNAME nohup $mpv "$@" >$logDIR/mpv-$timestamp.log 2>&1 &
