@echo off
set mediaFile=%~dpnx1
if not defined mediaFile (start mpui)  else start mpui %mediaFile%
