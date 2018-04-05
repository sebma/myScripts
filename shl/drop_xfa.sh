#!/usr/bin/sh

pdftk $1 cat output $1_NO_XFA.pdf drop_xfa
