gin WindowsProductName,BiosFirmwareType,CsManufacturer,CsModel,CsChassisSKUNumber,CsProcessors,CsTotalPhysicalMemory,OsName,OsVersion,CsNetworkAdapters,CsName,CsUserName,OsPagingFiles,TimeZone
echo "UserProfile`t      : $ENV:USERPROFILE"
Get-PSDrive -PSProvider FileSystem | Format-Table
