#!/usr/bin/env bash

sudo apt-key adv --keyserver-options http-proxy=$http_proxy --keyserver keyserver.ubuntu.com --keyring /usr/share/keyrings/onlyoffice.gpg --recv-keys CB2DE8E5

echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee /etc/apt/sources.list.d/onlyoffice.list

sudo apt install onlyoffice-desktopeditors -V
