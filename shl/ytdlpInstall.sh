#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
$sudo pipx install --global yt-dlp[default,curl-cffi]
