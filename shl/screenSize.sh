#!/usr/bin/env sh

xrandr | awk '/ connected/{print sqrt( ($(NF-2)/10)^2 + ($NF/10)^2 )/2.54" inches"}'
