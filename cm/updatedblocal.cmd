@echo off
call clean_cache || exit/b 1
call cleartmp || exit/b 2
echo.
updtdb32 -cU -L1 -LP:
REM @updtdb32
exit 0
