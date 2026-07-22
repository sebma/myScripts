@echo off
@cp.exe -puv %*
@echo.
set srcDir=%~dp1
set dstDir=%2
set filePattern=%1

echo robocopy -njh -njs %srcDir% %dstDir% %filePattern%
