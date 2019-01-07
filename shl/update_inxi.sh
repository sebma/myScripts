#!/usr/bin/env sh

rm -v ../pl/not_mine/inxi
LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/master/inxi.1
#LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ../pl/not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/inxi
LANG=C \curl -q --no-progress-bar -C - -R -z ../pl/not_mine/inxi -o ../pl/not_mine/inxi https://raw.githubusercontent.com/smxi/inxi/master/inxi
chmod +x ../pl/not_mine/inxi
