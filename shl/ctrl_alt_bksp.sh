#!/usr/bin/env sh

setxkbmap -option terminate:ctrl_alt_bksp
dconf write /org/gnome/desktop/input-sources/xkb-options "\[\'terminate:ctrl_alt_bksp\'\]"
