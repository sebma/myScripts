#!/usr/bin/env bash

curl -fsSL https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$(lsb_release -sr)/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
installPackagesFromRepo.sh "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$(lsb_release -sr)/ /" albert
~/.local/share/albert/python/venv/bin/pip install --disable-pip-version-check translators
