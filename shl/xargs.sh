#!/usr/bin/env sh

command="$1"
shift
if \xargs --help 2>&1 | grep -wq -- -o;then
	\xargs -o $command "$@"
else
	parallel --tty -X $command "$@"
fi
