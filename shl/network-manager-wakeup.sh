#!/usr/bin/env bash

# This script must be put in /etc/pm/sleep.d/ directory
# This script gets NetworkManager out of suspend.

case $1 in
    resume|thaw) nmcli nm sleep false;;
esac
