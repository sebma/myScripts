@echo on
powershell Get-ExecutionPolicy | findstr -i RemoteSigned >NUL || powershell "Set-ExecutionPolicy RemoteSigned -scope CurrentUser"
powershell Get-ExecutionPolicy
powershell -Set-ExecutionPolicy RemoteSigned -File "../psh/psh_CreateNewProfile_N_Initialize.ps1"

