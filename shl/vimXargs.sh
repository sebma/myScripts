#!/usr/bin/env sh

if \xargs --help | grep -wq -- -o;then
	\xargs -o vim "$@"
else
	parallel --tty -X vim "$@"
fi
