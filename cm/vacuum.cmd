@echo off
pushd
tasklist /v | findstr /i firefox && (
  echo.
  echo Firefox is still running, you must stop Firefox first.
  exit/b 1
)

cd/d "%userprofile%\Application Data\Mozilla\Firefox\Profiles\"
for /r %%f in (*.sqlite) do (
  echo Compacting file %%f ...
  echo VACUUM; | sqlite3 "%%f"
)

cd/d "%userprofile%\Local Settings\Application Data\Mozilla\Firefox\Profiles\"
for /r %%f in (*.sqlite) do (
  echo Compacting file %%f ...
  echo VACUUM; | sqlite3 "%%f"
)
popd
