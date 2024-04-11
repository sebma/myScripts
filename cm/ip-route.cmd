@REM route -4 print | findstr -r "[0-9].[0-9].[0-9].[0-9].*[0-9]$" | findstr -v "224.0.0.0 255.255.255.255"
route -4 print | findstr "On-link 0.0.0.0 Gateway Persistent" | findstr -v "224.0.0.0 255.255.255.255"
netsh int ipv4 sh route | findstr -v "224.0.0.0/4 /32"
