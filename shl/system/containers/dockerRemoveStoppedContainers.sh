#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=sudo
$sudo docker ps -a | awk '/Exited/{print$1}' | $sudo xargs -rt docker rm
