@echo off
REM Make first partition (Windows Recovery) bootable
(
echo select disk 0
echo select volume C:
echo active
echo list volume
) > activate_C_drive.dpt

diskpart -s activate_C_drive.dpt
del activate_C_drive.dpt
echo.
echo on

bootrec /FixMbr && bootrec /FixBoot && bootrec /ScanOs
bootrec /RebuildBcd || chkdsk /f c:
bootrec /RebuildBcd || chkdsk /r c:
bcdboot c:\windows /s c: && cd /d c: && expand bootmgr temp
