@pushd .
@tasklist | findstr -i firefox.exe >nul && (
  echo =^> Firefox is running !
  exit/b 1 
) || (
  @cd/d "%userprofile%\Local Settings\Application Data\Mozilla\Firefox\Profiles\" && (
    del/s _cache*_
    del/s *d01
    popd
  ) 2>nul
)

@tasklist | findstr -i sumatrapdf.exe >nul && echo =^> SumatraPDF is running ! || del P:\bin\sumatrapdfcache\*.png
