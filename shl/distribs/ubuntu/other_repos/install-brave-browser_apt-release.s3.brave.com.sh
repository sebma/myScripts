#!/usr/bin/env bash

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0686B78420038257
installPackagesFromRepo.sh "https://brave-browser-apt-release.s3.brave.com/ stable main" brave-browser
