@echo off
set dosformatFile=%1
if not defined dosformatFile exit/b 1

net use lpt2: >nul 2>&1 || (
  echo =^> ERREUR: Le port lpt2 ne pointe sur rien. >&2
  exit/b 2
)

unix2dos %dosformatFile%
print /d:lpt2 %dosformatFile%
