#!/usr/bin/env bash

if which linux-purge >/dev/null 2>&1;then
	echo "=> linux-purge is already installed." >&2
	exit 1
else
	sh -c 'cd /tmp && wget -N https://git.launchpad.net/linux-purge/plain/install-linux-purge.sh && chmod +x ./install-linux-purge.sh && sudo ./install-linux-purge.sh && rm ./install-linux-purge.sh' && [ "$BASH" ] && echo Replaced current shell in order to make the Bash completion work. && exec bash
fi
