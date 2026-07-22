@echo off
set newDriveLetter=%1
if not defined newDriveLetter (
  echo =^> Usage: %0 newDriveLetter >&2
  exit/b -1
)

for /F "tokens=3" %%A in ('echo list volume ^| diskpart ^| find "-ROM "') do set cdrom=%%A:
for /F "tokens=*" %%B in ('mountvol %cdrom% /L') do set volguid=%%B

:: Remove letter assigned to found CD/DVD-ROM drive
mountvol %cdrom% /d
:: Assign new letter to previously unmounted CD/DVD-ROM drive 
mountvol %newDriveLetter% %volguid%
