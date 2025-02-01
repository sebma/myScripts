#!/usr/bin/env sh

interpreter=$(readlink -f /proc/$$/exe)
interpreter=$(basename $interpreter)
echo "=> interpreter = <$interpreter>"
