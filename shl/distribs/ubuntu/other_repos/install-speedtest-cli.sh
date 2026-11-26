#!/usr/bin/env bash

installPackagesFromRepo.sh "https://packagecloud.io/ookla/speedtest-cli/ubuntu/ $(lsb_release -sc) main" speedtest-cli
