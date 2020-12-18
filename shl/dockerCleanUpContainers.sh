#!/usr/bin/env sh

docker ps -f status=exited | awk '/Exited/{printf" "$1}' | \xargs -rt docker rm
