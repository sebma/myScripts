#!/usr/bin/env bash

wget -qO - https://pkg.axoflow.io/axoflow-code-signing-pub.asc | gpg --dearmor | sudo tee /usr/share/keyrings/axoflow-code-signing-pub.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/axoflow-code-signing-pub.gpg] https://pkg.axoflow.io/apt stable ubuntu-$(lsb_release -sc)" | sudo tee /etc/apt/sources.list.d/axoflow.list
sudo apt update
sudo apt install -V axosyslog
