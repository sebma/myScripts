#!/usr/bin/env bash

setleds +num
type -P sudo >/dev/null 2>&1 && sudo="sudo" || sudo=""
pgrep gpm >/dev/null || gpm -m /dev/input/mouse0 -t ps2
#time $sudo emerge-webrsync -v || time $sudo emerge --sync && $sudo etc-update --automode -3
#eselect news read >/dev/null
