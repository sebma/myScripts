#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
which dra >/dev/null 2>&1 && $sudo dra download -a -i -o /usr/local/bin/dra devmatteini/dra
