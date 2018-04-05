#!/bin/sh

for repo in universe multiverse
do
  sudo software-properties-gtk --enable-component=$repo
done

sudo apt-get update -qq
