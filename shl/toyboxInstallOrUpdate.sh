#!/usr/bin/env sh

\wget -nv http://landley.net/toybox/bin/toybox-$(uname -m) -P /tmp/
sudo install -vpm755 /tmp/toybox-$(uname -m) /usr/local/bin/toybox
sudo install -vpm755 /tmp/toybox-$(uname -m) /bin/toybox
sync
/usr/local/bin/toybox --version
/usr/local/bin/toybox --help
