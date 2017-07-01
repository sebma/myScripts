@for /f "skip=4 tokens=3" %%s in ('reg query hklm\system\currentcontrolset\services\w32time\parameters /v NtpServer') do @echo %%s
