@echo off
for %%f in (%*) do (
  openssl sha1 < %%f
  echo   %%f
)
