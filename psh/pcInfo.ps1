gin WindowsProductName , BiosFirmwareType , CsManufacturer , CsModel , CsChassisSKUNumber , CsProcessors , CsTotalPhysicalMemory , OsName , OsVersion, OsLanguage, OsMuiLanguages , CsNetworkAdapters , CsName , CsUserName , OsPagingFiles , TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
Get-SMBMapping
Get-PSDrive -PSProvider FileSystem | Format-Table
#Get-PSDrive -PSProvider FileSystem | Format-Table Name , @{ N="Used";E={ "{0:n3} GiB" -f ($_.Used/1GB) };A="right" } , @{ N="Free";E={ "{0:n3} GiB" -f ($_.Free/1GB) };A="right" } , @{ N="Total";E={ "{0:n3} GiB" -f (($_.Used+$_.Free)/1GB) };A="right" }
Get-Volume
#Get-NetIPAddress -AddressFamily IPv4  | select InterfaceAlias , IPAddress | Sort-Object InterfaceAlias | Format-Table
Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv4 | % { Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength , @{ Name='IPv4DefaultGateway'; Expression={ ( $_ | Get-NetIPConfiguration ).IPv4DefaultGateway.Nexthop } } | Format-Table
Get-NetRoute -AddressFamily IPv4 | select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "224.0.0.0/4|/32"
Get-WmiObject -Class Win32_Product | select Name , Version , InstallDate | sort Name
