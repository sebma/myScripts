@echo off
set pythonMSI=python-3.3.2
set python2Dir=D:\Python33


assoc .py
ftype | findstr -i python
if not exist %python2Dir%\python.exe (
  if not exist %pythonMSI% echo =^> ERROR: "%0" cannot find the "%pythonMSI%" file. >&2 && pause && exit /b 1
REM  start /wait msiexec -i %pythonMSI% -promptrestart -qb!+ allusers=1 targetdir=%python2Dir% addlocal=all
  start /wait msiexec -i %pythonMSI% -promptrestart -qb! allusers=1 targetdir=%python2Dir% addlocal=all
)

@echo off
assoc .py
ftype | findstr -i Python.File
echo %path% | findstr -i "%python2Dir%" >nul && pause || (
  echo =^> Ajout de "%python2Dir%" dans le PATH systeme ...
  setx path "%path%;%python2Dir%" -m
  pause
  exit
)
