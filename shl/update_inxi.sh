#!/usr/bin/env sh

#LANG=C wget --no-check-certificate --content-disposition --no-continue -N -P not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/inxi
LANG=C curl -q --no-progress-bar -C - -R -z not_mine/inxi -o not_mine/inxi https://raw.githubusercontent.com/smxi/inxi/master/inxi
