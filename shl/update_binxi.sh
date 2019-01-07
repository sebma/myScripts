#!/usr/bin/env sh

LANG=C wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/master/binxi.1
#LANG=C wget --no-check-certificate --content-disposition --no-continue -N -P ../shl/not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/binxi
LANG=C curl -q --no-progress-bar -C - -R -z ../shl/not_mine/inxi -o ../shl/not_mine/inxi https://raw.githubusercontent.com/smxi/inxi/master/binxi
