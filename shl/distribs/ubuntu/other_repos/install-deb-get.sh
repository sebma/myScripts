#!/usr/bin/env bash

if ! which deb-get >/dev/null 2>&1;then
	sudo apt install curl lsb-release wget jq -Vy
	curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
fi
