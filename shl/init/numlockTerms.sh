#!/usr/bin/env sh

# Turn Numlock on for the TTYs:
for tty in /dev/tty[1-6]; do
    setleds -v -D +num < $tty
done
