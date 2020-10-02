#!/usr/bin/env sh

command="$1"
shift
if \xargs --help | grep -wq -- -o;then
	\xargs -o $command "$@"
else
	parallel --tty -X $command "$@"
fi
