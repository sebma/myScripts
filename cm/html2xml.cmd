@echo off
set fileName=%1
@echo on
tidy -asxhtml -numeric -quiet -indent --force-output 1 %fileName% > %~dpn1.xml
