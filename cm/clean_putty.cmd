@echo off
set inputFile=%1
set outputFile=%~dpn1.new

sed "s/\x1b\[[0-9]*\;?[0-9]*[hm]//g" %inputFile% > %outputFile%
