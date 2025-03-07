#gwmi Win32_Product | ? Name -notMatch "update|microsoft" | Select Name , Version , InstallDate | Sort Name | Format-Table
#gci HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall | % { gp $_.PsPath } | ? Displayname -notMatch "update|microsoft" | Select Displayname , DisplayVersion , InstallDate | Sort -u Displayname | Format-Table | Out-String -Stream | % { $_.Trim() }
Get-Package | ? Name -notMatch "update|microsoft" | Select Name , Version | Sort Name | Format-Table -AutoSize
