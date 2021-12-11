#!/usr/bin/env bash

wiresharkGroup=wireshark
grep -wq $wiresharkGroup /etc/group || sudo groupadd  --system $wiresharkGroup
ls -l $(which dumpcap) | grep -q $wiresharkGroup || sudo chown -v root:$wiresharkGroup $(which dumpcap)
setcap -q -v cap_net_raw,cap_net_admin=eip $(which dumpcap) || sudo setcap cap_net_raw,cap_net_admin=eip $(which dumpcap)
groups | grep -qw $wiresharkGroup || sudo usermod -a -G $wiresharkGroup $USER
