#!/usr/bin/env sh

docker ps -a | awk '/Exited/{printf" "$1}' | \xargs -rt docker rm
