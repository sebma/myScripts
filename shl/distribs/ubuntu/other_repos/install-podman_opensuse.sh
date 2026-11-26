#!/usr/bin/env bash

if ! apt-cache -q=0 policy podman-compose 2>&1 | grep '^N:' -q;then
	sudo apt install -V podman podman-compose
else
	installPackagesFromRepo.sh "http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$(lsb_release -sr)/ /" podman podman-compose
	if ! grep $USER /etc/subuid;then
		start=$(awk -F: '/^[a-zA-Z]/{start=$2+$3}END{printf start}' /etc/subuid)
		count=$((2**16))
		last=$(($start+$count-1))
		usermod --add-subuids $start-$last --add-subgids $start-$last $USER
	fi
fi
