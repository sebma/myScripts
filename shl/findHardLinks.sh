#!/usr/bin/env bash

find="command find"
if sudo true;then
#	sudo $find . ! -type l -printf "%y\t%n\t%p\n" 2>/dev/null | awk '($1 == "f" && $2 > 1) || ($1 == "d" && $2 > 2) {print}'
	sudo $find . -type f -printf "%y\t%n\t%p\n" 2>/dev/null | awk '($1 == "f" && $2 > 1) {print}'
fi
