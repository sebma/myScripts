#!/usr/bin/env bash

topd () {
	[ $# = 0 ] && local lines=10 || local lines=$1
	du -cxhd 1 2>/dev/null | grep -v '\s*\.$' | sort -hr | head -n $lines
}

topd "$@"
