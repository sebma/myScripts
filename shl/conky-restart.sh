#!/usr/bin/env bash

restart_conky() {
	while ! \pgrep kwin >/dev/null
	do
		sleep 1
	done
	\pgrep conky >/dev/null && \killall -SIGUSR1 conky || conky -d
}

restart_conky "$@"
