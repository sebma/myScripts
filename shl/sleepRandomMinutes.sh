#!/usr/bin/env bash

randomN () {
	test $# -gt 1 || test "$1" = "-h" && {
		echo "=> Usage: $FUNCNAME [N=100]" 1>&2
		return 1
	}
	[ $# = 1 ] && local N=$1 || local N=100
	local b=$((2**15-1))
	test "$N" -gt $b && {
		echo "=> [$FUNCNAME] ERROR: N must be lower than 2^15" 1>&2
		echo 0
		return 2
	}
	local n=$RANDOM
	echo $((N*n/b))
}
sleepRandomMinutes () {
	test $# -gt 1 || test "$1" = "-h" && {
		echo "=> Usage: $FUNCNAME [N=10]" 1>&2
		return 1
	}
	[ $# = 1 ] && local N=$1 || local N=10
	local random=$(randomN $N)
	[ $? = 0 ] && sleep ${random}m || return $?
}

sleepRandomMinutes "$@"
