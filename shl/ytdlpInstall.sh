#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(which sudo)
$sudo pipx install --global yt-dlp[default,curl-cffi]
