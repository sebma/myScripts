gin WindowsProductName , BiosFirmwareType , CsManufacturer , CsModel , CsChassisSKUNumber , CsProcessors , CsTotalPhysicalMemory , OsName , OsVersion, OsLanguage, OsMuiLanguages , CsNetworkAdapters , CsName , CsUserName , OsPagingFiles , TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
Get-PSDrive -PSProvider FileSystem | Format-Table
Get-PSDrive -PSProvider FileSystem | Format-Table -Property Name,Used,Free
Get-NetIPAddress -AddressFamily IPv4  | select InterfaceAlias , IPAddress | Sort-Object InterfaceAlias
