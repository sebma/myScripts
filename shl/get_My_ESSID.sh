#!/usr/bin/env bash

type -P iwgetid >/dev/null && iwgetid | awk '/ESSID:/{print $NF}' || nmcli dev wifi list | awk '$NF ~ /yes/{print $1}'
