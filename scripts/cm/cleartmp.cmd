@echo off

pushd .
cd/d "%tmp%" && (
  echo Supression des fichiers temporaires dans %tmp% ...
  rd/q/s .
  popd
) 2>nul

pushd .

tasklist | findstr -i sumatrapdf.exe >nul || del P:\bin\sumatrapdfcache\*.png P:\SumatraPDF\sumatrapdfcache\*.png

tasklist | findstr -i outlook.exe >nul && (
  echo =^> Oulook is running !
  exit /b 1
  ) || (
  cd/d "%userprofile%\Local Settings\Temporary Internet Files\" && (
    echo Supression des fichiers temporaires dans "%userprofile%\Local Settings\Temporary Internet Files\ ..."
    rd/q/s OLK*
    popd
  )
)

