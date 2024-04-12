echo "=> Clearing the destinationcache cache ..."
gsudo.exe -u t2-sma netsh interface ip delete destinationcache

echo '=> Printing the route via "route print" simplifed :'
echo ''
route -4 print | sls "On-link|0.0.0.0|Gateway" | sls -n "224.0.0.0|255.255.255.255"
echo ''

echo '=> Printing default routes via "netsh int ip sh route" ...'
echo ''
netsh int ipv4 sh route | sls -n "/32|224.0.0.0/4"

echo '=> Printing the route via "Get-NetRoute -AddressFamily IPv4" :'
Get-NetRoute -AddressFamily IPv4 | select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "224.0.0.0/4|/32"
