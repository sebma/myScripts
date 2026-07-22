@echo off
SETLOCAL EnableDelayedExpansion
set OrginalServiceName=%1
set NewServiceName=%2
set NewDisplayName=%3

if not defined OrginalServiceName goto usage
if not defined NewServiceName goto usage
if not defined NewDisplayName goto usage

for /f "skip=4 tokens=1,2*" %%r in ('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%OrginalServiceName%') do (
  echo %%r | find "HKEY_LOCAL_MACHINE" >NUL || (
    if %%r==Description set description=%%t
    if %%r==Type set type=%%t
    if %%r==Start set start=%%t
    if %%r==ErrorControl set error=%%t
    if %%r==ImagePath set binPath=%%t
    if %%r==Group set group=%%t
    if %%r==DependOnService set depend=%%t
    if %%r==Tag set tag=%%t
    if %%r==ObjectName set obj=%%t
  )
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
 
echo =^> sc create %NewServiceName% type= %type% start= %start% error= %error% binPath= "%binPath%" group= "%group%" tag= %tag% DisplayName= %NewDisplayName% depend= %depend% obj= %obj% ...
sc create %NewServiceName% type= %type% start= %start% error= %error% binPath= "%binPath%" group= "%group%" tag= %tag% DisplayName= %NewDisplayName% depend= %depend% obj= %obj%
if defined description (
  echo =^> sc description %NewServiceName% "%description%"
  sc description %NewServiceName% "%description%"
)

sc qc %NewServiceName% && echo =^> Le service [%NewServiceName%] a bien ete cree.

goto end
:usage
  echo =^> Usage: %~n0 [OrginalServiceName] [NewServiceName] [NewDisplayName]
  exit/b 1
:end
