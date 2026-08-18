#!/usr/bin/env bash

xrandr | awk '/ connected.*[0-9]+/{print sqrt( ($(NF-2)/10)^2 + ($NF/10)^2 )/2.54" inches"}'
