#!/usr/bin/env sh
#export SNAP=/snap/chromium/current
export SNAP=$(snap run --shell chromium -c 'echo $SNAP')
bash $SNAP/bin/chromium.launcher &
