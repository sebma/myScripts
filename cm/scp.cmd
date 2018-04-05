@echo off
echo %1 | findstr -r "^-" >nul && set option=%1 && shift
set src=%1
set dest=%2
if not defined dest set dest=.
echo %src% | find ":" >nul && set src=%username%@%src%
echo %dest% | find ":" >nul && set dest=%username%@%dest%
pscp -p %option% %src% %dest%
