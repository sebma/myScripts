#!/usr/bin/env python
#coding: latin1

import os
import argparse
from sys import argv, stderr, exit
from os.path import exists, basename
import inspect
from datetime import datetime
from os import getenv
from subprocess import Popen, check_output, PIPE
import re
from pdb import set_trace #To add a breakpoint for PDB debugger

def printStringToFile(fileName, string) :
	fileHandle = open( fileName, "a" )

	print >> fileHandle, string

	fileHandle.close()

def printNLogError(error) :
	if error :
		logFileHandle = open( args.logFileName, "a")
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		error = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error
		print >> stderr, error
		print >> logFileHandle, error
		logFileHandle.close()

def printNLogErrorAndExit(error, rc) :
	if error :
		printNLogError(error)
		printNLogError( "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n" )
		print >> stderr, "=> Le fichier de log est: < " + logFileName + " >.\n"
		exit(rc)

def runCommandAndReturnOutput(myCommand) :
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def getEnvironmentFromScript( envFile ) :
	if   os.name == "nt"    : myCommand = "call " + envFile + " > " + os.devnull + " & set"
	elif os.name == "posix" : myCommand = ". " +    envFile + " > " + os.devnull + "&& env"

	myStdout = Popen( myCommand, stdout=PIPE, shell=True, universal_newlines=True ).communicate()[0]

	return myStdout

def setEnvironmentFromString( environment ) :
	for line in environment.splitlines() :
		variable = line.split( "=" )[0]
		value = line.split( "=" )[1]
		if value != getenv( variable ) :
			os.environ[ variable ] = value

def initArgs() :
	parser = argparse.ArgumentParser(description = 'Script equivalent à celui de requete_tom.bat.')
	parser.add_argument("SPN", help="Symbolic Partner Name")
	parser.add_argument("SFN", help="Symbolic File Name")
	parser.add_argument("srcFileName", help="source file name")
	parser.add_argument("allDSN", help="DSN")
	parser.add_argument("direction", help="transfert direction")
	parser.add_argument("type", help="transfert type")
	parser.add_argument("logFileName", help="other optional arguments")

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

	global pid
	pid = str( os.getpid() )

	global logFileName
	if args.logFileName : logFileName = args.logFileName
	else : print >> stderr, "=> The log file < " + args.logFileName + " > does not exist." ; exit(-2)

def initScript() :
	if not exists( args.srcFileName ) : printNLogErrorAndExit( "The sourcefile < " + args.srcFileName + " > does not exists anymore.", -2 )
	printStringToFile( args.logFileName, "The script < " + scriptBaseName + " > is started the following way:\n[pid=" + pid + "]: " + " ".join(argv) )

	defvareurScript = getenv("DEFVAREUR")
	environment = getEnvironmentFromScript( defvareurScript )
	setEnvironmentFromString( environment )
	global tomExe
	tomExe = getenv( "TOM_EXE" )

def findParameterInLines( lines, parameter, separator1 = ' ' ) :
	result = ""
	for currentLine in lines.splitlines() :
		if parameter in currentLine :
			if separator1 != ' ' :
				spaceSplitted = currentLine.split( ' ' )
				for assignment in spaceSplitted :
					if parameter in assignment :
						line = re.sub( separator1 + '+' , separator1, currentLine ) #Replace multiple occurences of separators by separator1
						result = assignment.split( separator1 )[ 1 ]
						return result

	return result

def findParameterInLinesBetweenTwoSeparators( lines, parameter, separator1 = ' ', separator2 = ' ' ) :
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

def main() :
	initArgs()
	initScript()
#	tomReqCmd = "type transfertOK.txt"
	tomReqCmd = tomExe + os.sep + "tomreq.exe" + " /P:" + args.SPN + " /F:" + args.SFN + " /D:" + args.srcFileName + " /3:" + args.allDSN  +  " /B:" + args.allDSN  + " /S:" + args.direction + " /T:" + args.type + " /C:ADMIN /M:ADMIN"

	printStringToFile( args.logFileName, "tomReqCmd = " + tomReqCmd )
	stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( tomReqCmd )
	printStringToFile( args.logFileName, stdoutStr )

	# print stdoutStr
	if stderrStr :
		printStringToFile( args.logFileName, stderrStr )
		print >> stderr, stderrStr

	if   retCode == 1 :
		printStringToFile( args.logFileName, "Erreur du Moniteur C:X")
	elif retCode == 2 :
		printStringToFile( args.logFileName, "Erreur de l'API")
	elif retCode == 3 :
		printStringToFile( args.logFileName, "Erreur dans les parametres")

	if retCode == 0 :
		TRN = findParameterInLinesBetweenTwoSeparators( stdoutStr, "Requete:" )
		if TRN :
			print TRN
			printStringToFile( args.logFileName, "=> INFO: The transfert reqest number : " + TRN + " of the file < " + args.srcFileName + " > ended ok." )
		else :
			print "0"
			printStringToFile( args.logFileName, "=> ERROR: Could not fetch thr Transfert Request number." )

	printNLogError( "FIN du script: < " + scriptBaseName + " > avec le code de retour : <" + str( retCode ) + ">.\n" )
	print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + args.logFileName + " >.\n"
	exit( retCode )

main()

