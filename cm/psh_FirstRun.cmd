@echo on
powershell Get-ExecutionPolicy | findstr -i RemoteSigned >NUL || powershell "Set-ExecutionPolicy RemoteSigned"
powershell Get-ExecutionPolicy
powershell 'New-Item -Path $Profile -ItemType file -Force'
powershell 'notepad $Profile'
