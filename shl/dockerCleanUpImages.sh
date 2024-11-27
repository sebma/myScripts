#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=sudo
$sudo docker image ls | awk '/^<none>\s+<none>/{printf" "$3}' | $sudo xargs -rt docker rmi
