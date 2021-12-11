#!/usr/bin/env bash

command="$1"
shift
if \xargs --help 2>&1 | grep -wq -- -o;then
	\xargs -o $command "$@"
else
	\xargs sh -c $command' </dev/tty "$@"' whatever
fi
