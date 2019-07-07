@echo off

net localgroup Administrateurs | find /i "ARPEGESECUREXP-DEV" >nul && echo =^> C'est un poste Developpeur || echo =^> Ce n'est pas un poste Developpeur

::Activation du theme classic
reg query hkcu\Software\Microsoft\Windows\CurrentVersion\Themes\LastTheme /v "displayname of modified" | findstr /i /r displayname.*classi >nul || rundll32 shell32.dll,Control_RunDLL desk.cpl desk,@themes /Action:OpenTheme /File:"%WinDir%\Resources\Themes\Windows Classic.theme"

::Activation du surlignage des raccourcis claviers
reg add "hkcu\Control Panel\Desktop" /v UserPreferencesMask /d BE3E0580 /t REG_BINARY /f

reg add "hkcu\software\policies\microsoft\internet explorer\control panel" /v HomePage /d 0 /f

reg add "hkcu\software\microsoft\windows\currentVersion\applets\systray" /v Services /d 0x1f /t REG_DWORD /f

reg add "hkcu\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartMenuFavorites /d 0x2 /t REG_DWORD /f

reg delete "hkcu\software\microsoft\windows\currentVersion\policies" /f || (
  reg delete "hkcu\software\microsoft\windows\currentVersion\policies\system" /v NoDispScrSavPage /f
  reg delete "hkcu\software\microsoft\windows\currentVersion\policies\system" /v DisableRegistryTools /f
)

reg delete "HKCU\Software\Policies\Microsoft\Internet Explorer" /f

reg add "hklm\software\microsoft\windows nt\currentversion\winlogon" /v AllocateCDRoms /t REG_SZ /d 1 /f

set myNetworkMAP=P:
set myFirefoxProfileDir=%myNetworkMAP%\Mozilla\Firefox\Profiles\sebman

set IEFavoritesDir=%1
if not defined IEFavoritesDir set IEFavoritesDir=IEPortableFavorites
if not exist %myNetworkMAP%\%IEFavoritesDir% mkdir %myNetworkMAP%\%IEFavoritesDir%

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" | findstr /i /r Favorites.*%IEFavoritesDir% || (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Favorites /d %myNetworkMAP%\%IEFavoritesDir% /f
  start "" %myNetworkMAP%\%IEFavoritesDir%
)

setlocal ENABLEDELAYEDEXPANSION

reg add "hklm\software\microsoft\windows nt\currentversion\winlogon" /v AllocateCDRoms /t REG_SZ /d 1 /f

reg add "hkcu\software\microsoft\windows\currentversion\Explorer\User Shell Folders" /v Programs /d %myNetworkMAP%\Programs /f
reg add "hkcu\software\microsoft\windows\currentversion\Explorer\User Shell Folders" /v SendTo /d %myNetworkMAP%\SendTo /f
reg add "hkcu\software\microsoft\windows\currentversion\Explorer\User Shell Folders" /v Startup /d %myNetworkMAP%\Programs\D‚marrage /f

if not defined appdata2 (
  set appdata2="%userprofile%\Local Settings\Application Data"
  setx appdata2 !appdata2!
)

set SER_HOME=\\arpege.socgen\data\SIOP\DSI\PFI-SEI\SER
set PFP_HOME="\\arpege.socgen\data\SIOP\DSI\PFI-SEI\SER\ELAPS\PFP ELAPS"
setx SER_HOME %SER_HOME%
setx PFP_HOME %PFP_HOME%

dir l: >nul 2>&1 || (
  net use l: >nul 2>&1 && net use l: /d
  net use l: %PFP_HOME% /persistent:yes
)
dir t: >nul 2>&1 || (
  net use t: >nul 2>&1 && net use t: /d
  net use t: %SER_HOME%\SER_PUBLIC /persistent:yes
)

reg add hkcu\environment /v prompt /t reg_expand_sz /d  [$S%%username%%$S@$S%%computername%%$S$P]$_$$$S /f

echo %path% | findstr /i "%myNetworkMAP%\bin;%myNetworkMAP%\cm;%myNetworkMAP%\putty" >nul || setx path "%myNetworkMAP%\bin;%myNetworkMAP%\cm;%myNetworkMAP%\putty"

echo %pathext% | findstr /i .msc >nul || setx pathext %pathext%;.msc
echo %pathext% | findstr /i .cpl >nul || setx pathext %pathext%;.cpl

setx dircmd /ogen/-c
setx home "%userprofile%"
setx desktop "%userprofile%\bureau"
if not defined sysdir setx sysdir "%windir%\system32"

echo %LOGONSERVER% | findstr /i vdf >nul && (
  set printerList=\\impvdf002\ma5505179-kyfs1900 \\impvdf003\ma5510169-kyfs2000 \\impvdf001\ma0314506-epal4200
  set defaultPrinter=\\impvdf002\ma5505179-kyfs1900
)

echo %LOGONSERVER% | findstr /i def >nul && (
  set printerList=\\impdef004\ma0286738-cair4080 \\impdef005\ma5530861-xxxxxxxx
  set defaultPrinter=\\impdef005\ma5530861-xxxxxxxx
)

for %%p in (%printerList%) do (
  cscript %windir%\system32\prnmngr.vbs -l | findstr /i %%p > nul || (
    con2prt /c %%p
  )
)

con2prt /cd %defaultPrinter%
::cscript %windir%\system32\prnmngr.vbs -l | findstr /i 
net use lpt2: >nul 2>&1 || net use lpt2: %defaultPrinter% /persistent:yes

reg query "hkcu\software\microsoft\windows desktop search\ds" >nul 2>&1 && reg add "hkcu\software\microsoft\windows desktop search\ds" /v ShowStartSearchBand /t REG_DWORD /d 0 /f

::cscript %windir%\system32\prnmngr.vbs -l | findstr /i PDFCreator >nul && cscript %windir%\system32\prncnfg.vbs -x -p PDFCreator -z PDF
reg import %myNetworkMAP%\bin\locate32.reg

endlocal

::exit
