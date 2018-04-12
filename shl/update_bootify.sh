#!/usr/bin/env sh

LANG=C wget -P not_mine/ https://raw.githubusercontent.com/oneohthree/bootify/master/bootify.sh
ln -vsf not_mine/bootify.sh bootify.sh
