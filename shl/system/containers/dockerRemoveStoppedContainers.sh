#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
$sudo docker ps -a | awk '/Exited/{print$1}' | $sudo xargs -rt docker rm
