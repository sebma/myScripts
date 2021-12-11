#!/usr/bin/env bash

for repo in universe multiverse
do
#	sudo software-properties-gtk --enable-component=$repo
	sudo add-apt-repository $repo
done

sudo apt-get update -qq
