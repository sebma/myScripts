#!/usr/bin/env sh

chromium_snap_start() {
	local SNAP=$(snap run --shell chromium -c 'echo $SNAP')
	local SNAP_USER_COMMON=$(snap run --shell chromium -c 'echo $SNAP_USER_COMMON')
	SNAP=$SNAP SNAP_USER_COMMON=$SNAP_USER_COMMON $SNAP/bin/chromium.launcher "$@" &
}
chromium_snap_start "$@"
