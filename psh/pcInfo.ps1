$today = $( get-date -f "yyyyMMdd" )
& {
echo "=> PC Summary info :"
gin WindowsProductName , BiosFirmwareType , CsManufacturer , CsModel , CsChassisSKUNumber , CsProcessors , CsTotalPhysicalMemory , OsName , OsVersion, OsLanguage, OsMuiLanguages , CsNetworkAdapters , CsName , CsUserName , OsPagingFiles , TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
echo ""
echo "=> AD Info :"
Get-ADComputer $env:COMPUTERNAME 2>$null
Get-ADUser $env:USERNAME 2>$null
Get-ADDomainController -Discover 2>$null | % HostName
echo $env:LOGONSERVER.Substring(2)
echo "=> Network Maps :"
Get-SMBMapping | Format-Table
echo "=> Network Drives Usage :"
Get-PSDrive -PSProvider FileSystem | Format-Table
#Get-PSDrive -PSProvider FileSystem | Format-Table Name , @{ N="Used";E={ "{0:n3} GiB" -f ($_.Used/1GB) };A="right" } , @{ N="Free";E={ "{0:n3} GiB" -f ($_.Free/1GB) };A="right" } , @{ N="Total";E={ "{0:n3} GiB" -f (($_.Used+$_.Free)/1GB) };A="right" }
echo "=> Volumes Usage :"
Get-Volume
#Get-NetIPAddress -AddressFamily IPv4  | Select InterfaceAlias , IPAddress | Sort InterfaceAlias | Format-Table
echo ""
echo "=> IP information :"
Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv4 | % { Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $_.InterfaceAlias } | Select InterfaceAlias , IPAddress , PrefixLength , @{ Name='IPv4DefaultGateway'; Expression={ ( $_ | Get-NetIPConfiguration ).IPv4DefaultGateway.Nexthop } } | Format-Table
echo "=> Routing table :"
Get-NetRoute -AddressFamily IPv4 | Select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "224.0.0.0/4|/32"
echo "=> Software List :"
#wmic product get name,version,installDate | sls -n "^\s*$" | Out-String -stream | Sort { ($_.trim() -split '\s+')[1] }
#Get-WmiObject -Class Win32_Product | Select Name , Version , InstallDate | Sort Name | Format-Table
#Get-Package | ? Name -notMatch "update|microsoft" | Select Name , Version , InstallDate | Sort Name | Format-Table -AutoSize
ls HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall | % { gp $_.PsPath } | Select Displayname , DisplayVersion , InstallDate | Sort -u Displayname | Format-Table
echo "=> Running Services :"
Get-Service | ? Status -eq "Running" | select Status , Name , DisplayName
} | Tee "$env:COMPUTERNAME-$today.txt"
