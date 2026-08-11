#[string[]]( Get-NetRoute -DestinationPrefix 0.0.0.0/0 | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | ft | Out-String | % { $_.Trim() } )
echo "=> Clearing the destinationcache cache ..."
gsudo -u t2-sma netsh interface ip delete destinationcache

echo '=> Printing default routes via "route print" ...'
echo ''
route -4 print | sls "Netmask|0.0.0.0.*0.0.0.0"
echo ''

echo '=> Printing default routes via "netsh int ip sh route" ...'
echo ''
netsh int ipv4 show route | sls "Prefix|0.0.0.0/0"
echo ''

echo '=> Printing default routes via "Get-NetRoute -DestinationPrefix 0.0.0.0/0" ...'
Get-NetRoute -DestinationPrefix 0.0.0.0/0 | select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric| Format-Table
