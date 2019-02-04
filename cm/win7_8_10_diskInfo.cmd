@echo off
REM show Windows disk boot information
(
echo select disk 0
echo list partition
echo list volume
) > diskInfo.dpt

prompt $$$s
echo on
diskpart -s diskInfo.dpt
del diskInfo.dpt
echo.
bcdedit
bootrec /ScanOs
@prompt
