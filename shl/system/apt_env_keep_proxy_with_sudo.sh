#!/usr/bin/env bash

sudo sh -c "egrep '^Defaults.*env_keep.*http?_proxy' /etc/sudoers /etc/sudoers.d/* -q" || echo 'Defaults:%sudo env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"' | sudo tee /etc/sudoers.d/proxy
