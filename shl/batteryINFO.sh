#!/usr/bin/env sh

set -x
acpi -bi
inxi -Bxxx
upower -i $(upower -e | grep BAT)
