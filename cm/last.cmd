@echo off
set day=%1
set user=%2
if not defined day set day=0
if not defined user set user=%username%
psloglist -d 0 security >nul && psloglist -o security -i 528,551 -s -t "\t" security -d %day% 2>nul | findstr /i %user%
