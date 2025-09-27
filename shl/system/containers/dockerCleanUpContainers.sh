#!/usr/bin/env bash

type sudo >/dev/null 2>&1 && [ $(id -u) != 0 ] && groups | egrep -wq "sudo|adm|admin|root|wheel" && sudo="sudo" || sudo=""
groups | egrep -w docker && docker=docker || docker="$sudo docker"

$docker ps -f status=exited | awk '/Exited/{printf" "$1}' | \xargs -rt $docker rm
