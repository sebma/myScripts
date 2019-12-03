#!/usr/bin/env sh

adb shell dumpsys battery | \sed 's/\r//' | egrep 'Current Battery|level|scale'
