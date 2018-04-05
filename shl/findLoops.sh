#!/usr/bin/env sh

findLoops() {
    $(which find) . "$@" -o -follow -printf "" 2>&1 | egrep -w "loop|denied"
}

findLoops "$@"
type nbPages
