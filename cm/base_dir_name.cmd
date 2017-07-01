@echo off
set File=%~1
echo File=%File%
for /f "tokens=*" %%a in ("%File%") do @(
	set basename="%%~nxa"
	set dirname="%%~dpa"
)

echo =^> basename = %basename%
echo =^> dirname = %dirname%
