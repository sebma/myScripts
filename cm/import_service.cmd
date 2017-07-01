@echo off
set OrginalServiceName=%~n1
set NewServiceName=%2
set NewDisplayName=%3

if not defined OrginalServiceName goto usage
if not defined NewServiceName set NewServiceName=%OrginalServiceName%

for /f "tokens=1,2*" %%a in ('findstr -v "HKEY_LOCAL_MACHINE REG.EXE" %OrginalServiceName%.txt') do (
	if %%a==Description set description=%%c
	if %%a==DisplayName set displayname=%%c
	if %%a==Type set type=%%c
	if %%a==Start set start=%%c
	if %%a==ErrorControl set error=%%c
	if %%a==ImagePath set binPath=%%c
	if %%a==Group set group=%%c
	if %%a==DependOnService set depend=%%c
	if %%a==Tag set tag=%%c
	if %%a==ObjectName set obj=%%c
)

if not defined NewDisplayName set NewDisplayName=%displayname%

if not defined type (
	echo ERROR: type is not defined. >&2
	exit/b 1
)

::On supprime les "\0\0" et on remplace les "\0" par des "/" ssi la variable est definie
if defined depend set depend=%value:\0\0=%
if defined depend set depend=%value:\0=/%

if not defined obj set obj=""
if not defined depend set depend=""

if %type%==0x1 set type=kernel
if %type%==0x2 set type=filesys
if %type%==0x10 set type=own
if %type%==0x20 set type=share
if %type%==0x110 set type=own type= interact
::Attention, les guillemets ici sont obligatoires car la valeur de la variable contient un espace
if "%type%"=="0x120" set type=share type= interact

if %start%==0x2 set start=auto
if %start%==0x3 set start=demand
if %start%==0x4 set start=disabled

if %error%==0x0 set error=ignore
if %error%==0x1 set error=normal

set tag=no

echo =^> sc create %NewServiceName% type= %type% start= %start% error= %error% binPath= "%binPath%" group= "%group%" tag= %tag% DisplayName= "%NewDisplayName%" depend= %depend% obj= %obj% ...
sc create %NewServiceName% type= %type% start= %start% error= %error% binPath= "%binPath%" group= "%group%" tag= %tag% DisplayName= "%NewDisplayName%" depend= %depend% obj= %obj%
if defined description (
	echo =^> sc description %NewServiceName% "%description%"
	sc description %NewServiceName% "%description%"
)

sc qc %NewServiceName% && echo =^> Le service [%NewServiceName%] a bien ete cree.

goto end

:usage
	echo =^> Usage: %~n0 OrginalServiceName.txt [NewServiceName] [NewDisplayName]
	exit/b 1
:end
