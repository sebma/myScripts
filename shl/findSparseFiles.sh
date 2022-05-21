#!/usr/bin/env bash

find="$(type -P find)"
if sudo true;then
	sudo $find . -type f -printf "%S\t%p\n" 2>/dev/null | awk '$1 > 0 && $1 < 1.0 {print}'
fi
