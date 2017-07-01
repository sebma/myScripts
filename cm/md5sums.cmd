@echo off
for %%f in (%*) do (
  openssl md5 < %%f
  echo   %%f
)
