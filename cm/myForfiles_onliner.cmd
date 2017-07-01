@setlocal enabledelayedexpansion & for /r %%F in (*) do @set relpath=%%F & set relpath=!relpath:%cd%\=! & echo =^> Running command %~1 !relpath! ... >&2 & %~1 !relpath!
