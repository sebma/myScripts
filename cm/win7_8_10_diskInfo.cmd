@echo off
REM show Windows disk boot information

prompt $$$s
echo on
( echo sel disk 0 & echo list part & echo list volume ) | diskpart
echo.
bcdedit
bootrec /ScanOs
@prompt
