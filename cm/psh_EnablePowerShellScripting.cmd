@echo on
powershell Get-ExecutionPolicy | findstr -i RemoteSigned >NUL || powershell "Set-ExecutionPolicy RemoteSigned"
