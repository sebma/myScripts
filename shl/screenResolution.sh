#!/usr/bin/env bash

xrandr | awk -F'x| *' '/[^s]connected/{printf$1":\t"}/\+([^0]|$)/{print $2"x"$3}'
