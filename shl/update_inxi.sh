#!/usr/bin/env sh

LANG=C wget -P not_mine/ https://raw.githubusercontent.com/smxi/inxi/master/inxi
ln -vsf not_mine/inxi inxi
