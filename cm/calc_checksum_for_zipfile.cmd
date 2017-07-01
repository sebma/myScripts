@echo off
set zipfile="%1"
if not defined zipfile (
  echo =^> Usage: %0 ^<zip filename^>. >&2
  pause >nul
  exit/b 1
)

set zipfile="%~dp0\%1"
if not exist temp mkdir temp
pushd temp
for /f "skip=1 tokens=2" %%f in ('unzip -o %zipfile%') do (sha512sum %%f) 2>nul
popd
rd /q /s temp
