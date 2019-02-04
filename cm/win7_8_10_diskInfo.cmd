@echo off
REM show Windows disk boot information
(
echo select disk 0
echo list partition
echo list volume
) > diskInfo.dpt

diskpart -s diskInfo.dpt
del diskInfo.dpt
echo.
echo on

bcdedit
bootrec /ScanOs
