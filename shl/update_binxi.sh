#!/usr/bin/env sh

rm -v ../shl/not_mine/binxi
LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ~/.local/share/man/man1/ https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi.1
#LANG=C \wget --no-check-certificate --content-disposition --no-continue -N -P ../shl/not_mine/ https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi
LANG=C \curl -q --no-progress-bar -C - -R -z ../shl/not_mine/binxi -o ../shl/not_mine/binxi https://raw.githubusercontent.com/smxi/inxi/inxi-legacy/binxi
chmod +x ../shl/not_mine/binxi
