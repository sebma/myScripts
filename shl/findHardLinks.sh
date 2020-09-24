#!/usr/bin/env bash

find=$(which find)
if sudo true;then
	sudo $find . -printf "%n\t%p\n" 2>/dev/null | gawk '$1 > 1 {print}'
fi
