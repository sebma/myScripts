@for %%a in (%*) do @for %%e in (exe com cmd bat pl py rb vbs) do @for %%c in (%%a.%%e) do @echo.%%~$PATH:c | findstr -i %%c
