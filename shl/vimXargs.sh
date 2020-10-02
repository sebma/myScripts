#!/usr/bin/env sh

if \xargs --help 2>&1 | grep -wq -- -o;then
	\xargs -o vim "$@"
else
	parallel --tty -X vim "$@"
fi
