@echo off
set usr=%1
if not defined usr (
	echo =^> Usage: %0 username
	exit/b 1
)

wmic os get oslanguage -format:value 2>nul | findstr -i oslanguage=1033 >nul && (
	set rdpGroup=Remote Desktop Users
)

wmic os get oslanguage -format:value 2>nul | findstr -i oslanguage=1036 >nul && (
	set rdpGroup=Utilisateurs du Bureau … distance
)

net user %usr% 2>nul | findstr -i %usr% >nul || net user %usr% * /add

if not defined rdpGroup (
	echo =^> ERROR: The variable "rdpGroup" could not be initialised.>&2
	exit/b 1
)

net localgroup "%rdpGroup%" 2>nul | findstr -i %usr% >nul || net localgroup "%rdpGroup%" %usr% /add
