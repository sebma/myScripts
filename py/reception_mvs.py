#!/usr/bin/env python
#coding: latin1

import argparse
from sys import argv, stderr, exit
import sys
from platform import node, python_version_tuple
from os import getenv, chdir, getcwd, makedirs, removedirs, system, times
from os.path import exists, basename, dirname, splitext, abspath, relpath, isfile, isdir, getsize
import os
import re
from datetime import datetime
from random import randint
from shutil import copy2, rmtree, move
from subprocess import Popen, check_output, PIPE
from pdb import set_trace #To add a breakpoint for PDB debugger
import inspect
from logging import DEBUG, INFO, WARNING, ERROR, basicConfig, StreamHandler, Formatter, getLogger, info, debug, warning, warn, error

def checkPythonVersion( minimalVersion=2.6 ) :
	currentVersion = float( python_version_tuple()[0] + '.' + ''.join( python_version_tuple()[1:] ) )
	if currentVersion < minimalVersion :
		print >> stderr,  "=> ERROR: The minimum version needed for Python is <" + str(minimalVersion) + "> but you have the version <" + str(currentVersion) + ">" + " installed in < " + sys.prefix + " > on server <" + node() + ">.\n"
		return 1
	else :
		return 0

def isUnixScript(fileName) :
	if fileNewlineChar(fileName) != "\n" :
		print >> stderr, "=> ERROR: You must convert the script < " + fileName + " > to UNIX format so it can be run on both Windows and UNIX/Linux."
		exit(1)

def fileNewlineChar(fileName) :
	with open( fileName, "U" ) as fileHandle :
		fileHandle.readline()
		fileHandle.readline()
		newlineChar = fileHandle.newlines

	return newlineChar

def writeInTomLog(fileBaseName, destFileName, way) :
	tomLogFile = tomLogDir + os.sep + yearMonthDay + "-Journal.log"
	string = datetime.now().strftime("%Y/%m/%d;%H:%M:%S") + ";" + way + ";" + fileBaseName + ";" + destFileName + ";TRN=" + args.TRN

	printNLogInfo( "MAJ du Journal TOM: " + tomLogFile  ) 
	print string
	with open( tomLogFile, "a" ) as tomLogFileHandle :
		print >> tomLogFileHandle, string

def printStringInFile(fileName, string) :
	with open( fileName, "a" ) as fileHandle :
		print >> fileHandle, string

def printNLogString(string) :
	print string
	with open( logFileName, "a" ) as logFileHandle :
		print >> logFileHandle, string

def printNLogCommandOutput( stdoutString, stderrString ) :
	with open( logFileName, "a" ) as logFileHandle :
		if stdoutString : print >> logFileHandle, stdoutString; print stdoutString
		if stderrString : print >> logFileHandle, stderrString; print >> stderr, stderrString

def printNLogDebug(message) :
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		if args.TRN == "RESTART" :
			prefix = timestamp +      " - [PID=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "]"
		else :
			prefix = timestamp + " - [TRN=" + args.TRN + "][" + scriptBaseName + "][" + callerFunctionName + "]"

		message = prefix + "[DEBUG] - " + message
		print message
		with open( logFileName, "a" ) as logFileHandle :
			print >> logFileHandle, message

def printNLogInfo(message) :
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		if args.TRN == "RESTART" :
			prefix = timestamp +      " - [PID=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "]"
		else :
			prefix = timestamp + " - [TRN=" + args.TRN + "][" + scriptBaseName + "][" + callerFunctionName + "]"

		message = prefix + " - " + message
		print message
		with open( logFileName, "a" ) as logFileHandle :
			print >> logFileHandle, message

def printNLogError(error) :
	if error :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		if args.TRN == "RESTART" :
			error = timestamp + " - [PID=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error
		else :
			error = timestamp + " - [TRN=" + args.TRN + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error

		print >> stderr, error
		with open( logFileName, "a") as logFileHandle :
			print >> logFileHandle, error

def printNLogErrorAndExit(error, rc) :
	if error :
		printNLogError(error)
		printNLogError( "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n" )
		print "=> Le fichier de log est: < " + logFileName + " >.\n"
		exit(rc)

def runCommandAndReturnOutput(myCommand) :
	printNLogInfo( "RUNNING command: \n\n" + myCommand + "\n" )
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()
	printNLogInfo( "END of command with return code: <" + str(myProcess.returncode) + ">.\n" )

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def findParameterInFile( fileName, parameter, separator, pos ) :
	textFileHandle = open( fileName, "rt" )

	result = ""
	line = " "
	while line != "" :
		line = textFileHandle.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == "\n" : continue

		line = line.strip()
		if line != "" and line[0:3].lower() != "rem" and line[0] != "#" :
			if parameter in line :
				line = re.sub( separator + '+' , separator, line) #Replace multiple occurences of separators by separator
				if pos == "last" : result = line.split( separator )[-1]
				else : result = line.split( separator )[ int(pos) ]
				textFileHandle.close()

#				print >> stderr, "=> parameter = <" + result + ">."
				return result

	textFileHandle.close()
	return result

def copyNArchive(src,dst) :
	srcBaseName = basename(src)

	if not dst :
		printNLogErrorAndExit( "Error when transmitting the parameters.", 1 )

	printNLogInfo( "Checking if < " + src + "  > file was not already treated ..." )
	if not exists(archDir + os.sep + srcBaseName + ".arch") :
		try :
			printNLogInfo( "Copying < " + src + " > to < " + dst + " > ..." )
			copy2(src,dst)
		except IOError, e :
			printNLogError( "Unable to copy file. Retcode =" % e )
			return(2)
		else :
			printNLogInfo( "Moving < " + src + " > to < " + archDir + os.sep + srcBaseName + ".arch" + " > ..." )
			move(src, archDir + os.sep + srcBaseName + ".arch" )
			prevDir = getcwd()
			chdir( archDir + os.sep + ".." + os.sep + ".." )
			printNLogInfo( "Archiving < " + srcBaseName + " > in < " + abspath( archDir + os.sep + ".." + os.sep + ".." + os.sep + ".." + os.sep + yearMonth + ".zip" ) + " > ..." )
			system( "zip -9u " + yearMonth + ".zip " + relpath( archDir ) + os.sep + srcBaseName + ".arch")
			printNLogInfo( "Done." )
			chdir( prevDir )
			return(0)
	else :
		printNLogError( "The file < " + srcBaseName + " > was already treated, cf. " + archDir + os.sep + srcBaseName + ".arch" )
		funcName = inspect.stack()[0][3]
		printNLogError( "The function <" + funcName + "> returned: <" + str( 3 ) + ">." )
		print >> stderr
		return(3)

	return(0)

def getEnvironmentFromScript( envFile ) :
	if   os.name == "nt"    : myCommand = "call " + envFile + " > " + os.devnull + " & set"
	elif os.name == "posix" : myCommand = ". " +    envFile + " > " + os.devnull + "&& env"

	myStdout = Popen( myCommand, stdout=PIPE, shell=True, universal_newlines=True ).communicate()[0]

	return myStdout

def setEnvironmentFromString( environment ) :
	for line in environment.splitlines() :
		variable = line.split( "=" )[0]
		value = line.split( "=" )[1]
		try :
			if value != getenv( variable ) :
				os.environ[ variable ] = value
		except Error as why :
			printNLogError( "Could not set the variable < " + variable + " > to the value < " + value + " > because : " % why)
		except :
			printNLogError( "Could not set the variable < " + variable + " > to the value < " + value + " >  :\n" + sys.exc_info()[0] )

def findParameterInEnvironment( environment, parameter, separator ) :
	result = ""
	for assignment in environment.splitlines() :
		if parameter in assignment :
			assignment = re.sub( separator + '+' , separator, assignment ) #Replace multiple occurences of separators by separator
			result = assignment.split( separator )[ 1 ]

			return result

	return result

def findParameterInLines( lines, parameter, separator ) :
	result = ""
	for currentLine in lines.splitlines() :
		if parameter in currentLine :
			if separator != ' ' :
				spaceSplitted = currentLine.split( ' ' )
				for assignment in spaceSplitted :
					if parameter in assignment :
						line = re.sub( separator + '+' , separator, currentLine ) #Replace multiple occurences of separators by separator
						result = assignment.split( separator )[ 1 ]
						return result

	return result

def findParameterInLinesBetweenTwoSeparators( lines, parameter, separator1, separator2 ) :
	result = ""
	for currentLine in lines.splitlines() :
		if parameter in currentLine :
			currentLine = currentLine.strip()
			currentLine = re.sub( " +" , ' ', currentLine ) #Replace multiple occurences of blanks by one blank
			currentLine = re.sub( "( ?" + separator1 + " ?)+", separator1, currentLine ) #Replace multiple occurences of separators by separator1
			currentLine = re.sub( separator2 + '+' , separator2, currentLine ) #Replace multiple occurences of separators by separator2
			result = currentLine.split( parameter + separator1 )[-1].split( separator2 )[0]
			return result

	return result

def concat( fileList, dstFile ) :
	with open( dstFile, 'a') as outfile :
		for currFile in fileList :
			with open( currFile ) as infile :
				for line in infile :
					outfile.write(line)
				outfile.close()
			infile.close()

def renameLog( logFile ) :
	timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
	newLogFileName = dirname( logFile ) + os.sep + splitext( basename( logFile ) )[0] + "_" + timestamp + ".log"

	if exists( logFile ) :
		if not exists(newLogFileName) :
			try :
				move( logFile, newLogFileName )
			except IOError, e:
				print "Unable to move file. %s" % e
			else :
				printNLogInfo( logFile + " -> " + newLogFileName )
		else :
			printNLogInfo( "=> Le fichier <" + newLogFileName + "> existe deja donc on concatene la log dans <" + newLogFileName + ">." )
			fileList.append( logFile )
			concat( fileList, newLogFileName )
	else :
		printNLogError( "Le fichier < " + logFile + " > n'existe pas." )

def myGetEnv( variable ) :
	result = getenv( variable )
	if result is None : result = ""
	return result 

def initDates() :
	global day, month, year, yearMonth, yearMonthDay, theDate
	today = datetime.today()
	year = today.strftime('%Y')
	month = today.strftime('%m')
	day = today.strftime('%d')
	yearMonth = today.strftime('%Y%m')
	yearMonthDay = today.strftime('%Y%m%d')
	theDate = today.strftime('%d/%m/%Y')

def initLog() :
	initDates()

	# funcName = inspect.stack()[0][3]

	global logBaseDir, logFileName

	# logBaseDir = findParameterInEnvironment( environment, "RCV_LOG_DIR", "=" )
	# if not logBaseDir :
		# print >> stderr, "=> ERROR: The variable <RCV_LOG_DIR> is not defined."
		# exit(1)

	logBaseDir = nextDataMountPoint + os.sep + "LOGS" + os.sep + "Reception"
	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)
	# logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"
	# Regle le pb. du logging sur un fichier unique en multiprocess
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + "_" + args.TRN + ".log"
	newLogFileName = logFileName + ".NEW.log"

	if not exists(logFileName) or getsize(logFileName) == 0 :
		printNLogString( "="*82 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*82 )

	if not exists(newLogFileName) or getsize(newLogFileName) == 0 :
		printStringInFile( newLogFileName, "="*82 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*82 )

	consoleHandler = StreamHandler()
	consoleHandler.setLevel(INFO)
	consoleHandler.setFormatter( Formatter( fmt='%(levelname)-7s : %(message)s' ) )

	if args.TRN == "RESTART" :
		basicConfig(
					level=DEBUG,
					format='%(asctime)s.%(msecs)03d - [PID=%(process)d][%(filename)s][%(funcName)s:%(lineno)s] - %(levelname)-7s : %(message)s',
					datefmt='%X',
					filename=newLogFileName,
					filemode='a'
					)
	else :
		basicConfig(
					level=DEBUG,
					format='%(asctime)s.%(msecs)03d - [TRN=' + args.TRN + '][%(filename)s][%(funcName)s:%(lineno)s] - %(levelname)-7s : %(message)s',
					datefmt='%X',
					filename=newLogFileName,
					filemode='a'
					)

	getLogger().addHandler(consoleHandler) #Doit etre appele APRES le basicConfig

def initArgs() :
	global args, scriptBaseName

	parser = argparse.ArgumentParser()
	parser.add_argument("TRN", help="Transfert request number")
	parser.add_argument("SFN", help="Symbolic File Name")
	parser.add_argument("direction", help="transfert direction")
	parser.add_argument("SPN", help="Symbolic Partner Name")
	parser.add_argument("srcFileName", help="source file name")
	parser.add_argument("TRC", help="Transfer return code")
	parser.add_argument("PRC", help="PeSIT return code")
	parser.add_argument("fileBaseName", help="file basename")
	parser.add_argument("lastArgs", nargs='*', help="other optional arguments")

	args = parser.parse_args()
	scriptBaseName = parser.prog

def initScript() :
	funcName = inspect.stack()[0][3]
	isUnixScript(__file__)

	global debugFlag
	if getenv("debug_py") : debugFlag = True
	else : debugFlag = False

	initArgs()

	global currentDataMountPoint, nextDataMountPoint
	if   os.name == "nt"    : currentDataMountPoint = "D:"; nextDataMountPoint = "J:"
	elif os.name == "posix" : currentDataMountPoint = "/d"; nextDataMountPoint = "/j"

	initLog()
	# checkPythonVersion()

	global pid, hostname
	pid = str( os.getpid() )
	hostname = node()

	info("Retour a la fonction initScript.")
	printNLogString( "" )
	printNLogInfo( "Starting the script < " + scriptBaseName + " > which PID is < " + pid + " > on machine < " + hostname + " > the following way :\n" + " ".join( argv ) )
	if args.TRN == "RESTART" : printNLogInfo( "Running script <" + scriptBaseName +  "> in RESTART mode ..." )

	global defvareurScript, environment
	defvareurScript = myGetEnv("DEFVAREUR")
	if debugFlag : printNLogDebug( "Feching the environment variables from the a child process calling < " + defvareurScript +" > into the < environment > string ..." )
	if not defvareurScript :
		print >> stderr, "The environment variable <DEFVAREUR> is not defined."
		exit( -1 )
	else :
		environment = getEnvironmentFromScript( defvareurScript )
	if debugFlag : printNLogDebug( "Done." )

	if not exists( args.srcFileName ) : printNLogErrorAndExit( "The sourcefile < " + args.srcFileName + " > does not exists anymore.", -2 )

	try :
		if debugFlag : printNLogDebug( "Loading the environment variables stored in < environment > string ..." )
		setEnvironmentFromString( environment )
		if debugFlag : printNLogDebug( "Done." )

		if debugFlag : printNLogDebug( "Loading the variables TOM_DIR, RCV_DIR, LST_EXP_PART_PROD .." )
		global tomDir, rcvDir, numtrtReport, numtrtPatch
		tomDir = myGetEnv( "TOM_DIR" )
		if debugFlag : printNLogDebug( "TOM_DIR = " + tomDir)
		rcvDir = myGetEnv( "RCV_DIR" )
		numtrtReport = myGetEnv( "NUMTRT_REPORT" )
		numtrtPatch  = myGetEnv( "NUMTRT_PATCH" )
		lstExpPartProd = myGetEnv( "LST_EXP_PART_PROD" )
		if debugFlag : printNLogDebug( "Done." )

		if debugFlag : printNLogDebug( "Detecting the environment ..." )
		env = hostname[0]
		if   env == "D" : configParameter = "RCV_CFG_DEV";  envType = "Development"
		elif env == "H" : configParameter = "RCV_CFG_HOMO"; envType = "Homologation"
		elif env == "P" : configParameter = "RCV_CFG_PROD"; envType = "Production"
		if debugFlag : printNLogDebug( "The environment is: " + envType )

		global configFileName
		configDir = tomDir + os.sep + "Scripts"
		configBaseName = myGetEnv( configParameter  )
		if not configBaseName : printNLogErrorAndExit( "The parameter <" + configBaseName + "> was not found.", 2 )
		configFileName = configDir + os.sep + configBaseName

		if debugFlag : printNLogDebug( "Setting  the variables isProd, archDir, tomLogDir ..." )
		global isProd
		if args.SPN in lstExpPartProd : isProd = True
		else : isProd = False
		if debugFlag : printNLogDebug( "Done." )

		global archDir, tomLogDir
		archDir = dirname(args.srcFileName) + os.sep + "Arch" + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
		tomLogDir = tomDir + os.sep + "Journal" + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
		for dir in [ archDir, tomLogDir] :
			if not exists(dir) : makedirs(dir)
	except Error as why :
		printNLogError( "Something strange happened because: " % why)
	except :
		printNLogError( "Something strange happened." )

	printNLogInfo( "END of the < " + funcName + " > function." )

def main() :
	initScript()
	printNLogInfo( "Treating received file < " + args.srcFileName + " > on the " + theDate + "..." )
	printNLogInfo( "Symbolic File Name = <" + args.SFN + ">" )
	printNLogInfo( "Symbolic Partner Name = <" + args.SPN + ">" )
	printNLogInfo( "Flag Prod = " + str( isProd ) )

	qualifiers = args.fileBaseName.split(".")
	nbQualifiers = len(qualifiers)

	if qualifiers[0] == "TRANSTOM" :
		localPartner = qualifiers[1]
		appCode = qualifiers[2]
		trtID = qualifiers[3]
		dateField = qualifiers[4]

	if	 appCode[1:4] == "WPG" : application = "PHARE"
	elif appCode[1:4] == "ALI" : application = "ALISE"
	else :						 application = "UNKNOWN"

	printNLogInfo( "The remote application is : <" + application + ">." )

	if   application == "ALISE" :
		prefix = "MD" + trtID
		suffix = "xml"

		if nbQualifiers >= 6 : reqNum = qualifiers[5]
		if nbQualifiers >= 7 : timeField = qualifiers[6]

		dstDir = currentDataMountPoint + os.sep + "RAC" + os.sep + "SDD" + os.sep + "ALIRAC" + os.sep
		if   trtID == "OPE" : numTrt = "M6215" ; dstDir += "D" + trtID #UN TRES GRAND MERCI A JULIEN POUR SON SAVOIR FAIRE INEGALE POUR LES EXCEPTIONS
		elif trtID == "RJT" : numTrt = "M6216" ; dstDir += "C" + trtID
		elif trtID == "RPC" : numTrt = "M6217" ; dstDir += "C" + trtID
		elif trtID == "RVB" : numTrt = "M6218" ; dstDir += "C" + trtID

		fileBaseNameWithTrtNum = args.SPN + "." + localPartner + "." + numTrt + "." + reqNum + "." + dateField
	elif application == "PHARE" :
		# prefix = "PHARE-SD04-" + trtID
		prefix = appCode + "-" + trtID
		suffix = "xml"

		if nbQualifiers >= 6 : timeField = qualifiers[5]
		numTrt = "PHARE-SD04"

		#dstDir = currentDataMountPoint + os.sep + "Produits" + os.sep + "ELSAG" + os.sep + "FLUSSI" + os.sep + "THEMA" + os.sep + "OUTGOING"
		dstDir = nextDataMountPoint + os.sep + "DONNEES" + os.sep + application + os.sep + "TO_RNI" + os.sep + appCode[1:]
		fileBaseNameWithTrtNum = args.SPN + "." + localPartner + "." + numTrt + "." + timeField + "." + dateField
	else :
		numTrt = appCode
		printNLogErrorAndExit("Le code application <" + appCode + "> est inconnu.", -3)

	if not exists( dstDir ) : makedirs( dstDir )
	printNLogInfo( "numTrt = " + numTrt )
	if numTrt == numtrtReport :
		trtScriptName = tomDir + os.sep + "EXIT" + os.sep + "EUR" + env + "report.bat"
		intermediateDir = myGetEnv( "REPORT_DIR" )
	if numTrt == numtrtPatch :
		trtScriptName = tomDir + os.sep + "EXIT" + os.sep + "EURXpatch.bat"
		intermediateDir = myGetEnv( "PATCH_DIR" )
	else :
		trtScriptName = findParameterInFile( configFileName, numTrt, "\t", "1" )
		intermediateDir = myGetEnv( "RCV_DIR" )

	if not exists(intermediateDir) : makedirs(intermediateDir)

	fileNameWithTrtNum = intermediateDir + os.sep + fileBaseNameWithTrtNum
	srcBaseName = basename(args.srcFileName)
	retCode = copyNArchive(args.srcFileName, fileNameWithTrtNum)
	if retCode == 0 :
		if application == "ALISE" or application == "PHARE" :
#			command = trtScriptName + " " + intermediateDir + " " + fileBaseNameWithTrtNum
			hourMinutesSeconds = datetime.now().strftime("%H%M%S")
			aleatoire = randint( 1, 10**4 )
			destBaseName = prefix + "-" + yearMonthDay + "-" + hourMinutesSeconds + "-" + str(aleatoire) + "." + suffix
			destFileName = dstDir + os.sep + destBaseName

			try :
				printNLogInfo( "Moving the file < " + fileBaseNameWithTrtNum + " > to its final destination :" )
				move( fileNameWithTrtNum, destFileName )
			except IOError, e:
				print "Unable to move file. %s" % e
			else :
				printNLogInfo( fileNameWithTrtNum + " -> " + destFileName )
				writeInTomLog( fileBaseNameWithTrtNum, dstDir + os.sep + destBaseName , "RCV" )
		else :
			command = (
				"call " + defvareurScript + " >nul & cscript -nologo " + tomDir + os.sep + "EXIT"
				+ os.sep + "cfr_casheurope.vbs " + args.TRN + " " + fileBaseNameWithTrtNum + " " + fileNameWithTrtNum
				+ " " + args.SPN
			)

			stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( command )
			printStringInFile( logBaseDir + os.sep + args.TRN + ".log", stdoutStr )
			print stdoutStr
			if stderrStr :
				printStringInFile( logBaseDir + os.sep + "ERR_" + args.TRN + ".log", stderrStr )
				print >> stderr, stderrStr

			renameLog( logBaseDir + os.sep + args.TRN + ".log" )
			renameLog( logBaseDir + os.sep + "ERR_" + args.TRN + ".log" )

	printNLogInfo( "FIN du script: < " + __file__ + " > avec le code de retour : <" + str( retCode ) + ">.\n" )

	print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >."

	exit( retCode )

main()
