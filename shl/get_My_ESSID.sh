#!/usr/bin/env bash

which iwgetid >/dev/null && iwgetid | awk '/ESSID:/{print $NF}' || nmcli dev wifi list | awk '$NF ~ /yes/{print $1}'
