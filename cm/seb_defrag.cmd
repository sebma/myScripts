@echo off
set drive=%1
reg query "hkcu\software\microsoft\command processor" >nul 2>&1 && (
  echo =^> ERREUR: Il faut etre en mode sans echec pour pouvoir lancer "%0".
  exit/b 1
)

echo on
if not defined drive (
  set drive=d:
  defrag c:
)

defrag %drive% && shutdown -r -f -t 0
