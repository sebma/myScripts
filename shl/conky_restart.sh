#!/usr/bin/env bash

restart_conky() {
	while ! \pgrep plasma-desktop >/dev/null
	do
		sleep 1
	done
	\pgrep conky && \killall -SIGUSR1 conky || conky -d
}

restart_conky "$@"
