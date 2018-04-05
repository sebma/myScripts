@echo off

set sysDate=%date:* =%
set dd=%sysDate:~0,2%
set mm=%sysDate:~3,2%
set yyyy=%sysDate:~6,4%
set YYYYMMDD=%yyyy%%mm%%dd%

set hh=%time:~0,2%
set min=%time:~3,2%
set sec=%time:~6,2%

echo %dd%/%mm%/%yyyy% %hh%:%min%:%sec%

set hh=%hh: =0%

echo %dd%/%mm%/%yyyy% %hh%:%min%:%sec%
