#!/usr/bin/env sh

LANG=C wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/master/inxi.1
#LANG=C wget --no-check-certificate --content-disposition --no-continue -N -P ../py/not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/inxi
LANG=C curl -q --no-progress-bar -C - -R -z ../py/not_mine/inxi -o ../py/not_mine/inxi https://raw.githubusercontent.com/smxi/inxi/master/inxi
