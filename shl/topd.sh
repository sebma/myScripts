#!/usr/bin/env bash

topd () {
	du -cxhd 1 2>/dev/null | grep -v '\s*\.$' | sort -hr | head -n $1
}

topd "$1"
