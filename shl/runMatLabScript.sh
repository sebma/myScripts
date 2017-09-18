#!/usr/bin/env bash

args=$@
$(which matlab) -nojvm -r "${args/.m/}; exit"
