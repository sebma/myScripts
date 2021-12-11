#!/usr/bin/env bash

if \xargs --help 2>&1 | grep -wq -- -o;then
	\xargs -o vim "$@"
else
	\xargs sh -c vim' </dev/tty "$@"' whatever
fi
