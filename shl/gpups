#!/usr/bin/env bash

function gps {
	local pidList
	test -e /dev/nvidia0 && pidList=$(\lsof -n -w -t /dev/nvidia*)
	test -n "$pidList" && \ps $@ -p $pidList
}

gps $@
