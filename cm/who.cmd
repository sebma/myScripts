::@for /f "skip=1 tokens=1,2,* delims= " %%i in ('qwinsta console') do echo %%j
@qwinsta
