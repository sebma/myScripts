gin WindowsProductName , BiosFirmwareType , CsManufacturer , CsModel , CsChassisSKUNumber , CsProcessors , CsTotalPhysicalMemory , OsName , OsVersion, OsLanguage, OsMuiLanguages , CsNetworkAdapters , CsName , CsUserName , OsPagingFiles , TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
Get-PSDrive -PSProvider FileSystem | Format-Table
Get-PSDrive -PSProvider FileSystem | Format-Table -Property Name,Used,Free
Get-Volume
Get-NetIPAddress -AddressFamily IPv4  | select InterfaceAlias , IPAddress | Sort-Object InterfaceAlias | Format-Table
Get-NetRoute -AddressFamily IPv4 | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "224.0.0.0/4|/32"
