@echo off

set logFile=%computername%_routes.log
set routeDefinitionsFile=%~n0.lst

echo =^> Tests SSH ...
echo =^> Tests SSH ... >> %logFile% 2>&1

if exist %routeDefinitionsFile% (
  echo =^> Tests des routes ALISE a partir du poste de travail %computername% a %time% ...
  echo =^> Tests des routes ALISE a partir du poste de travail %computername% a %time% ... > %logFile%
  start tail.exe -f %logFile%
  for /f "tokens=*"  %%s in (%routeDefinitionsFile%) do (
    echo =^> telnet %%s ...
    nc.exe -v -z %%s && echo ==^> Route %%s: OK. || echo ==^> Route %%s: KO
  ) >> %logFile% 2>&1
) else (
  echo =^> Erreur le fichier "%routeDefinitionsFile%" n'existe pas. >&2
  exit /b -1
)

set serverList=dmut1.dns21 hmut1.dns21 hmut2.dns21

for %%s in (%serverList%) do (
  echo =^> telnet %%s 22 ...
  nc.exe -v -z %%s 22 && echo ==^> Route ssh %%s: OK. || echo ==^> Route ssh %%s: KO
) >> %logFile% 2>&1

echo =^> Tests des OutilsSG en HTTP ...
echo =^> Tests des OutilsSG en HTTP ... >> %logFile% 2>&1

set serverList=pmetro.dns20 gdi.si visufichier.si wclf01.dns21 dwebint.dns21

for %%s in (%serverList%) do (
  echo =^> telnet %%s http ...
  echo HEAD | nc.exe -v -z %%s http && echo  ==^> Route %%s http: OK. || echo ==^> Route %%s http: KO
) >> %logFile% 2>&1

echo =^> Tests des OutilsSG en HTTPS ...
echo =^> Tests des OutilsSG en HTTPS ... >> %logFile% 2>&1

set serverList=hapac apac origine.info.si gdec.info.si gipsy.infra.si password.sesame.si qualifdb.outil.si transnet.si visufichier.si hwebkli.dns21 pwebp5.dns20

for %%s in (%serverList%) do (
  echo =^> telnet %%s https ...
  nc.exe -v -z %%s https && echo ==^> Route %%s https: OK. || echo ==^> Route %%s https: KO
) >> %logFile% 2>&1

echo.
echo =^> Fin des tests de routes a %time%
echo =^> Fin des tests de routes a %time% >> %logFile%
echo.

pause
echo =^> Voici les routes KO fichier ^<%logFile%^> :
findstr KO %logFile%
echo.
taskkill /im tail.exe
