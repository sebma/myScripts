@echo off

echo.going to execute myDosFunc
call:myDosFunc
echo.returned to "%0"

echo.
goto:eof

:myDosFunc    - here starts my function identified by it`s label
echo Fontion "%0"
echo.  here the myDosFunc function is executing a group of commands
echo.  it could do a lot of things
goto:eof

:fonction
echo.  fonction numero 2
goto:eof
