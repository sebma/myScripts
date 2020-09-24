#!/usr/bin/env bash

find=$(which find)
if sudo true;then
	sudo $find . -type f -printf "%y %n\t%p\n" 2>/dev/null | gawk '($1 = "f" && $2 > 1) || ($1 = "d" && $2 > 2) {print}'
fi
