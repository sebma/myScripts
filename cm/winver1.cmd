@echo off
setlocal EnableDelayedExpansion

::Identify OS
for /F "delims=" %%a in ('ver') do set ver=%%a
set Version=
for %%a in (95=95 98=98 ME=ME NT=NT 2000=2000 5.1.=XP 5.2.=2003 6.0.=Vista 6.1.=7 6.2.=8) do (
   if "!Version!" equ "this" (
      set Version=Windows %%a
   ) else if "!ver: %%a=!" neq "%ver%" (
      set Version=this
   )
)

::Identify bit
if exist "%SYSTEMDRIVE%\Program Files (x86)" (
   set Type=64 bit
) else (
   set Type=32 bit
)

::Display result
echo %Version% %Type%
::echo/
::pause

::Goto right version
::goto %Version: =_%
goto :eof

:Windows_8
echo Windows 8

:Windows_7
echo Windows 7
