@echo off
set xmlFileName=%1
if not defined xmlFileName exit/b 1
shift
::sed "s/ xmlns=[^ ]*//" %xmlFileName% | xml select -t %1 %2 %3 %4 %5 %6 %7 %8 %9
xmllint --xpath %1 %xmlFileName%
