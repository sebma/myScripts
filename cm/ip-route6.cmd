route -6 print | findstr "On-link Gateway Persistent" | findstr -v -r "./128"
netsh int ipv6 sh route | findstr -v -r "./128"
