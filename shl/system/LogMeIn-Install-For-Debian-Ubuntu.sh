#!/usr/bin/env bash

# curl -sL https://repository.services.logmein.com/linux/setup_sh | sudo -E bash -x - # Le repo est mort
snap list logmein-host || sudo snap install logmein-host
xdg-open https://repository.services.logmein.com/linux
