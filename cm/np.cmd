@echo off
for %%f in (%*) do (
	start/b "" P:\bin\notepad2 %%f
)
