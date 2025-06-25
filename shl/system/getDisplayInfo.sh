#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
$sudo get-edid | parse-edid
