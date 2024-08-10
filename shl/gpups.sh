#!/usr/bin/env bash

function gpups {
	local pidList
	test -e /dev/nvidia0 && pidList=$(\lsof -n -w -t /dev/nvidia*)
	test -n "$pidList" && \ps $@ -p $pidList
}

gpups $@
