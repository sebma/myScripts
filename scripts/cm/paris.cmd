@echo off
::@start /b control timedate.cpl,,/z Central Europe Daylight Time
::@reg query "hklm\software\microsoft\windows nt\currentversion\time zones"
::@reg query hklm\system\currentcontrolset\control\timezoneinformation

wmic os get oslanguage -format:value | findstr 1036 >nul && (
  set language=fr
  start /b control timedate.cpl,,/z ^(GMT+01:00^) Bruxelles, Copenhague, Madrid, Paris
)
wmic os get oslanguage -format:value | findstr 1033 >nul && (
  set language=en
  start /b control timedate.cpl,,/z ^(GMT+01:00^) Brussels, Copenhagen, Madrid, Paris
)

::timezone /?
