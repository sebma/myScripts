#!/usr/bin/env sh

restart_conky() {
	while ! \pgrep kwin >/dev/null
	do
		sleep 1
	done
	\pgrep conky && \killall -SIGUSR1 conky || conky -d
}

restart_conky "$@"
