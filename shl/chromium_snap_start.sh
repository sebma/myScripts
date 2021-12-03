#!/usr/bin/env sh
SNAP=$(snap run --shell chromium -c 'echo $SNAP')
SNAP_USER_COMMON=$(snap run --shell chromium -c 'echo $SNAP_USER_COMMON')
SNAP=$SNAP SNAP_USER_COMMON=$SNAP_USER_COMMON $SNAP/bin/chromium.launcher &
