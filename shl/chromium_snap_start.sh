#!/usr/bin/env sh
export SNAP=/snap/chromium/$(snap list chromium | awk '/chromium/{printf$3}')
$SNAP/usr/lib/chromium-browser/chrome &
