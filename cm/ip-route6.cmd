route -6 print | findstr "On-link Gateway Persistent"
netsh int ipv6 sh route | findstr -v -r "./128"
