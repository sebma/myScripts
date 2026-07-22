@echo off
if not defined appdata2 setx -m appdata2 "%userprofile%\Local Settings\Application Data"
if not defined appdata2 set appdata2="%userprofile%\Local Settings\Application Data"

REM echo appdata2=%appdata2%

rmdir /q /s "%appdata%\Thinstall\" "%appdata2%\Thinstall\"
start/b "Effacement du cache et demarrage de IE8 ThinApp ..." "C:\Program Files\Microsoft\Internet Explorer (ThinApp)\8.0\Internet Explorer 8.exe"
