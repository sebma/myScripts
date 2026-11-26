#!/usr/bin/env bash

sudo apt purge -V containerd docker-compose
installPackagesFromRepo.sh "https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable" docker-ce docker-ce-rootless-extras docker-compose-plugin docker-buildx-plugin
if ! grep $USER /etc/subuid;then
	start=$(awk -F: '/^[a-zA-Z]/{start=$2+$3}END{printf start}' /etc/subuid)
	count=$((2**16))
	last=$(($start+$count-1))
	usermod --add-subuids $start-$last --add-subgids $start-$last $USER
fi
sudo groupadd docker
#sudo adduser $USER docker # i.e. https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
