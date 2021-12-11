#!/usr/bin/env bash

set -x
acpi -bi
inxi -Bxxx
upower -i $(upower -e | grep BAT)
