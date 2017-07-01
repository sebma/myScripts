@echo off
set firefoxProfileBase=%appdata%\Mozilla\Firefox\Profiles
for /d %%d in ("%firefoxProfileBase%\*.default") do @set firefoxProfile=%%d
echo.
::echo firefoxProfile=%firefoxProfile%
if not exist "%firefoxProfile%\plugins" mkdir "%firefoxProfile%\plugins"
xcopy /d /y %windir%\system32\Macromed\Flash\flashplayer.xpt "%firefoxProfile%\plugins\"
xcopy /d /y %windir%\system32\Macromed\Flash\NPSWF32*.dll "%firefoxProfile%\plugins\"
pushd "%firefoxProfile%\plugins"
move/y NPSWF32_*.dll NPSWF32.dll
popd
echo.
