@echo off

echo.
set destDir=x064304
set srcDir=x064304
tasklist | findstr /i outlook.exe >nul && echo =^> Oulook is running ! && exit/b 1 || (
  if /i %computername%==MA5154185 (
    echo =^> Sauvegarde de mes archives mails dans D:\%destDir%\ ...
    p:\bin\robocopy L:\%srcDir% D:\%destDir% *.pst -a-:sh -njh -ndl -nc -ns -eta -njs
  ) || (
    mountvol f: /l >nul && (set usbDrive=f:)  || (
      mountvol g: /l >nul && (set usbDrive=g:) || set usbDrive=
    )

    if defined usbDrive (
      echo =^> usbDrive = "%usbDrive%" 
      echo =^> Sauvegarde de mes archives mails dans %usbDrive%\%destDir%\ ...
      p:\bin\robocopy L:\%srcDir% %usbDrive%\%destDir% *.pst -a-:sh -njh -ndl -nc -ns -eta -njs
    ) else (
      echo =^> ERREUR: Aucune cle USB trouvee. 1>&2
      exit /b 1
    )
  )
)
exit/b
