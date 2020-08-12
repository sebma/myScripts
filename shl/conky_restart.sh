#!/usr/bin/env sh

restart_conky() {
	\pgrep conky && \killall -SIGUSR1 conky || conky -d
}

restart_conky "$@"
