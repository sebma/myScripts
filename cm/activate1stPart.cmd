@echo off
REM Make first partition (Windows Recovery) bootable
echo select disk 0 > activate1stPart.dpt
echo select partition 1 >> activate1stPart.dpt
echo active >> activate1stPart.dpt
echo list partition >> activate1stPart.dpt
diskpart -s activate1stPart.dpt
del activate1stPart.dpt
echo.
pause
