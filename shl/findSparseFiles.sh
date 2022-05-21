#!/usr/bin/env bash

find="$(type -P find)"
pwd -P | grep $HOME -q && sudo="" || sudo=sudo
$sudo $find . -type f -printf "%S\t%p\n" 2>/dev/null | awk '$1 > 0 && $1 < 1.0'
