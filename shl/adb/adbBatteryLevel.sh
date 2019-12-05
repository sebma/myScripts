#!/usr/bin/env sh

adb shell dumpsys battery | egrep 'Current Battery|level|scale' | tr -d '\r'
