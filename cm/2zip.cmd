@echo off
set filename=%~dpn1
zip -9mv "%filename%.zip" %*
