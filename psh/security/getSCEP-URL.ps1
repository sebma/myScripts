Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\SCEP' -Recurse | Get-ItemProperty | Select-Object PSPath,ServerURL | Where-Object ServerURL | Format-List
