#!/usr/bin/env bash

test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/devmatteini/dra/refs/heads/main/install.sh | $sudo bash -s -- --to /usr/local/bin/
