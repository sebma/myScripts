#!/usr/bin/env bash

realm discover $1 | awk -F "[: ]" '/required-package:/{print$5}' | grep -v samba-common-bin | xargs sudo apt-get install adsys sssd-ad -V -y
