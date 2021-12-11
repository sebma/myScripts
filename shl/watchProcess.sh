#!/usr/bin/env bash

function watchProcess {
	local pidList=""
	local ps="command ps"
	mkdir -p ~/log
	test $# = 1 && while true
	do
		pidList=$(\pgrep -f "$1")
		ppidList=$($ps -o ppid= $pidList && echo)
		test -n "$pidList" && ( $ps -fp $pidList && test -n "$ppidList" && echo "=> Showing the parent process :" && $ps h -fp $ppidList ) | tee -a ~/log/processSPY.log && break
		sleep 0.01
	done
}

watchProcess "$@"
