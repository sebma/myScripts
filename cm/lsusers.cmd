@echo off
set groupName=%1
if not defined groupName (
	echo =^> Usage: %0 groupName in AD >&2
	exit/b 1
)

for /f "tokens=1-3 usebackq skip=8" %%u in (`net group %groupName% /do ^| find /v "command"`) do @(
	if not "%%u"=="" net user %%u /do
	if not "%%v"=="" net user %%v /do
	if not "%%w"=="" net user %%w /do
) | findstr /r "Commentaire\>"
