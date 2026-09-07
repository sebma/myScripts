#!/usr/bin/env bash
[ $(id -u) != 0 ] && sudo=$(type -P sudo) || sudo=""
swapUsage=$(swapon -s | awk 'NR==2{printf "%d", 100*$4/$3}')
swapLimit=55
if [ $swapUsage -gt $swapLimit ];then
        if $sudo swapoff -va;then
                $sudo swapon -va;
        fi
fi
