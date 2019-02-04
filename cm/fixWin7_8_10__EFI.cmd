@echo off
REM Make first partition (Windows Recovery) bootable
REM (
REM echo select disk 0
REM echo select volume C:
REM echo active
REM echo list volume
REM ) > activate_C_drive.dpt

REM diskpart -s activate_C_drive.dpt
REM del activate_C_drive.dpt
echo.
echo on

bootrec /FixMbr && bootrec /FixBoot && bootrec /ScanOs
bootrec /RebuildBcd || chkdsk /f c:
bootrec /RebuildBcd || chkdsk /r c:
bcdboot c:\windows /s c: && cd /d c: && expand bootmgr temp
