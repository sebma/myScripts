#!/usr/bin/env bash

dpkg -l scrcpy-server && sudo apt purge -V scrcpy-server -y
installPackagesFromRepo.sh ppa:matteotenca/scrcpy scrcpy
