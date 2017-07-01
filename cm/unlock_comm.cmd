@reg add hkcu\software\policies\microsoft\communicator /v DisableFileTransfer /d 0 /t REG_DWORD /f
@taskkill -im communicator.exe -f
