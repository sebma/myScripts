#!/usr/bin/env bash

findLoops() {
#	local args=("$@")
	if [ $# = 0 ];then
	    time $(which find) . -xdev -follow -printf ""
	else
	    time $(which find) . -xdev "$@" -o -follow -printf ""
	fi
}

findLoops "$@"
