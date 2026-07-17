#!/usr/bin/env bash

time scaldisk iods list | grep -vw OK
time scaldisk iods list | grep -w OOS_PERM -q && scaldisk replace -d $(time scaldisk iods list | awk '/OOS_PERM/{print$1}')
time scaldisk iods list | grep -vw OK
