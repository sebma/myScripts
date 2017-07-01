@echo off

:main
	set ProgBaseName=%~nx0
	set ProgName=%~0
	call :initScript %*
	set funcName=main

	if not defined fileBaseName (
		call :printNLogERROR "Usage : %ProgName% numREQ SFN T/R SPN srcFileName TRC PRC fileBaseName"
		echo =^> Le fichier de log est: %logDIR%\%logfile%
		exit/b 1
	)

	if not defined TOM_DIR (
		call :printNLogMessage "La variable TOM_DIR n'est pas definie, chargement du fichier %DEFVAREUR% ..."
		call %DEFVAREUR%
	)

	call :printNLogMessage "TOM_DIR = %TOM_DIR%"

	setlocal enabledelayedexpansion
	for /f "tokens=1-6 delims=." %%a in ("!fileBaseName!") do (
		set localPartner=%%b
		set field4=%%d
		set dateField=%%e
		set reqNum=%%f

		call :printNLogMessage "Traitement du fichier: '!fileBaseName!' ..."
		call :printNLogMessage "Nom Physique Du FichierSource = %srcFileName%"
		call :printNLogMessage "Nom Du Partenaire Distant = %SPN%"
		echo.

		if !field4!==OPE (
			set destBaseName=!SPN!.!localPartner!.M6215.!reqNum!.!dateField!
		)
		if !field4!==RJT (
			set destBaseName=!SPN!.!localPartner!.M6216.!reqNum!.!dateField!
		)
		if !field4!==RPC (
			set destBaseName=!SPN!.!localPartner!.M6217.!reqNum!.!dateField!
		)
		if !field4!==RVB (
			set destBaseName=!SPN!.!localPartner!.M6218.!reqNum!.!dateField!
		)

		set destFileName=%destDIR%\!destBaseName!
		call :printNLogMessage "Nom Du Fichier Destination = !destBaseName!"
		call :copy_and_archive !srcFileName! !destFileName! && (
			call :printNLogMessage "DEBUT du script: %TOM_DIR%\EXIT\cfr_casheurope.vbs %numREQ% !destBaseName! !destFileName! %SPN% ..."
			call cscript //nologo %TOM_DIR%\EXIT\cfr_casheurope.vbs %numREQ% !destBaseName! !destFileName! %SPN%
			call :printNLogMessage "FIN du script: %TOM_DIR%\EXIT\cfr_casheurope.vbs"
			call :printNLogMessage "DEBUT du script: %TOM_DIR%\Scripts\renamelog.vbs %LOG_DIR%\%numREQ%.log"
			call cscript //nologo %TOM_DIR%\Scripts\renamelog.vbs %LOG_DIR%\%numREQ%.log
			call :printNLogMessage "FIN du script: %TOM_DIR%\Scripts\renamelog.vbs"
			call :printNLogMessage "DEBUT du script: %TOM_DIR%\Scripts\renamelog.vbs %LOG_DIR%\ERR_%numREQ%.log"
			call cscript //nologo %TOM_DIR%\Scripts\renamelog.vbs %LOG_DIR%\ERR_%numREQ%.log
			call :printNLogMessage "FIN du script: %TOM_DIR%\Scripts\renamelog.vbs"
		)
	)
	endlocal

	call :printNLogMessage "FIN du script: %ProgName%"
	echo.>> %logDIR%\%logfile%
	echo =^> Le fichier de log est: %logDIR%\%logfile%
	goto :eof

:copy_and_archive
	setlocal
	set funcName=%0
	set funcName=%funcName::=%
	set src=%1
	set srcBaseName=%~nx1
	call :printNLogMessage "srcBaseName = %srcBaseName%"
	set dst=%2

	if not defined dst (
		call :printNLogERROR "Pb. lors de la recuperation des parametres."
		endlocal
		exit/b 1
	)

	if not exist %archDIR%\%srcBaseName%.arch (
		copy %src% %dst% && call :printNLogMessage "Copie de %src% vers %dst% ..."
		move %src% %archDIR%\%srcBaseName%.arch
		call :printNLogMessage "Archiving %srcBaseName% in %archDIR%\..\%Year%%Month%.zip"
		pushd %archDIR%\..
		zip -9 %Year%%Month%.zip -u %Year%%Month%\%srcBaseName%.arch
		popd
	) else (
		call :printNLogMessage "Le fichier %src% a deja ete traite, cf. %archDIR%\%srcBaseName%.arch"
		exit/b 2
	)
	endlocal

	@exit /b %errorlevel%

:initScript
	set funcName=%0
	set funcName=%funcName::=%

	set sysDate=%date:* =%
	set Day=%sysDate:~0,2%
	set Month=%sysDate:~3,2%
	set Year=%sysDate:~6,4%
	set YYYYMMDD=%Year%%Month%%Day%

	set Heure=%time:~0,2%
	set Heure=%Heure: =0%
	set Minute=%time:~3,2%
	set Seconde=%time:~6,2%

	set numREQ=%1
	set SFN=%2

	set SPN=%4
	set srcFileName=%5
	set fileBaseName=%~8

	set srcDIR=d:\Reception_MVS
	set destDIR=d:\Exploit\TOM\Reception
	set archDIR=d:\Reception_MVS\Arch\%Year%%Month%
	set logDIR=D:\Produits\Tom\Logs\%Year%%Month%

	set logFile=%~n0_%Year%_%Month%_%Day%.log

	for %%d in (%srcDIR% %destDIR% %archDIR% %logDIR%) do (
		if not exist %%d mkdir %%d
	)

	echo =^> Debut de la log du programme %ProgBaseName% du %Day%/%Month%/%Year%>> %logDIR%\%logFile%
	echo =^> Debut de la log du programme %ProgBaseName% du %Day%/%Month%/%Year%
	call :printNLogMessage "Les arguments de %ProgBaseName% sont: %*"

	goto :eof

:printNLogMessage
	setlocal
	set msg=%time% - [%ProgBaseName%] [%funcName%] - %~1
	echo %msg%
	echo %msg%>> %logDIR%\%logFile%
	endlocal
	goto :eof

:printNLogERROR
	setlocal
	set msg=%time% - [%ProgBaseName%] [%funcName%] - ERROR: %~1
	echo %msg% >&2
	echo %msg%>> %logDIR%\%logFile%
	endlocal
	goto :eof
