#!/usr/bin/env bash

swapUsage=$(swapon -s | awk 'NR==2{printf "%d", 100*$4/$3}')
swapLimit=55
if [ $swapUsage -gt $swapLimit ];then
        if swapoff -va;then
                swapon -va;
        fi
fi
