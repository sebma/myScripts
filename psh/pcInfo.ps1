gin WindowsProductName,BiosFirmwareType,CsManufacturer,CsModel,CsChassisSKUNumber,CsProcessors,CsTotalPhysicalMemory,OsName,OsVersion,CsNetworkAdapters,CsName,CsUserName,OsPagingFiles,TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
Get-PSDrive -PSProvider FileSystem | Format-Table
Get-PSDrive -PSProvider FileSystem | Format-Table -Property Name,Used,Free
