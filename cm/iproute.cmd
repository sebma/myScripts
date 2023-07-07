@REM route -4 print | findstr -r "[0-9].[0-9].[0-9].[0-9].*[0-9]$" | findstr -v "224.0.0.0 255.255.255.255"
route -4 print | findstr -r "On-link 0.0.0.0" | findstr -v "224.0.0.0 255.255.255.255"
