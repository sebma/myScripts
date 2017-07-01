@setlocal enabledelayedexpansion
@for /r %%F in (*) do @(
	set relpath=%%F
	set relpath=!relpath:%cd%\=!
	sha512sum !relpath!
)
