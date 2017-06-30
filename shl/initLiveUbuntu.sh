#!/bin/sh

sudo loadkeys fr-latin9
for tty in /dev/tty[1-6]; do
  sudo setleds -D +num < $tty
done

sudo adduser $USER video

wget -qO/dev/null www.google.com && sudo apt-get install -qqy numlockx gpm
type numlockx >/dev/null && numlockx on

grep -q "^[ ]*deb cdrom:" /etc/apt/sources.list && sudo sed -i "/deb cdrom:/s/^/# /" /etc/apt/sources.list

for repo in universe multiverse
do
  grep -q "^[^#].*$repo$" /etc/apt/sources.list || sudo sed -i "/^deb [^c]\|^deb-src [^c]/s/$/ $repo/" /etc/apt/sources.list
done

grep -q Europe/Paris /etc/timezone || echo Europe/Paris | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

sudo update-pciids 
set -x
wget -qO/dev/null www.google.com && time -p sudo apt-get update -qq
