@echo off

set srcFileName=%8

set srcDIR="C:\RepertoireSource"
if not exist %srcDIR% (
  echo =^> Le repertoire %srcDIR% n'existe pas.
  exit /b 1
)

set destDIR="D:\RepertoireDestination"
if not exist %destDIR% (
  echo =^> Le repertoire %destDIR% n'existe pas.
  exit /b 1
)

set ArchDIR="D:\RepertoireARCHIVES"
if not exist %ArchDIR% (
  echo =^> Le repertoire %ArchDIR% n'existe pas.
  exit /b 1
)


for /f "tokens=1-6 delims=." %%a in (%srcFileName%) do (
  if %%d==AARA xcopy /d /y %srcDIR%\%srcFileName% %destDIR%\%srcFileName%.PSR && move %srcDIR%\%srcFileName% %ArchDIR%\  
  if %%d==PAIN xcopy /d /y %srcDIR%\%srcFileName% %destDIR%\%srcFileName%.PSR && move %srcDIR%\%srcFileName% %ArchDIR%\  
  if %%d==CAMT xcopy /d /y %srcDIR%\%srcFileName% %destDIR%\%srcFileName%.C54 && move %srcDIR%\%srcFileName% %ArchDIR%\  
)
