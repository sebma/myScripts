#!/usr/bin/env sh

docker images | awk '/^<none>\s+<none>/{printf" "$3}' | \xargs -rt docker rmi
