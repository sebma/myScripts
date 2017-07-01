@echo off
call :isAdmin
exit/b %errorlevel%
goto :eof

:isAdmin
	echo.>%windir%\system32\test && del %windir%\system32\test || exit/b

	goto :eof
