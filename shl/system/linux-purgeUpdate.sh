#!/usr/bin/env bash

if ! which linux-purge >/dev/null 2>&1;then
	echo "=> linux-purge is NOT installed." >&2
	exit 1
else
	sudo sh -c 'cd /usr/local/bin/ &&
wget -N https://git.launchpad.net/linux-purge/plain/update-linux-purge &&
chmod +x update-linux-purge'
	sudo update-linux-purge
	sudo ldconfig
	linux-purge --version
fi
