@echo off
set user=%1
if not defined user set user=%username%
net user %user% /domain | findstr "complet Commentaire"
