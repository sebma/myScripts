#!/usr/bin/env bash

nmcli dev wifi list | awk '$NF ~ /yes/{print $2}'
