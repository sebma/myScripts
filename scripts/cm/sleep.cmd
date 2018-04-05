@echo off
set /a nbSec=%1
set /a nbSec+=1
ping -n %nbSec% 127.0.0.1>nul
