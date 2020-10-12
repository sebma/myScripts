@echo off
REM show Windows disk boot information

prompt $$$s
echo on
( echo list disk & echo sel disk 0 & echo list part & echo list volume ) > diskInfo.dpt
cat diskInfo.dpt
diskpart -s diskInfo.dpt
echo.
bcdedit
bootrec /ScanOs
@prompt
