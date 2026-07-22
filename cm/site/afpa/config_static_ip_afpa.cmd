netsh int ipv4 add addr lan 192.168.22.141
netsh int ipv4 add addr lan gateway=192.168.22.200 gwmetric=1
netsh int ipv4 add dns lan 192.168.28.247
netsh int ipv4 add dns lan 9.9.9.9 index=2
netsh int ip sh addr lan
