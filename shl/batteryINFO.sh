#!/usr/bin/env bash

inxi -Bxxx "$@"
if [ $(uname -s) = Linux ];then
	set -x
	acpi -bi
	upower -i $(upower -e | grep BAT)
fi
