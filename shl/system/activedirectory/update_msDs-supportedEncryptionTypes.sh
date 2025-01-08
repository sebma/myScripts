#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=sudo
$sudo msktutil update --dont-change-password --enctypes 0x18
