#!/usr/bin/env python
#coding: latin1

import os
from sys import argv, stderr, exit
import inspect
from os import getenv, makedirs
from os.path import exists, basename, splitext, dirname, isabs
from datetime import datetime
import re
import argparse
from subprocess import check_output, Popen, PIPE

def printNLogString(string) :
	logFileHandle = open( logFileName, "a" )

	print >> logFileHandle, string
	print string

	logFileHandle.close()

def printNLogInfo(message) :
	logFileHandle = open( logFileName, "a" )
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		message = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	print >> logFileHandle, message
	logFileHandle.close()

def printNLogError(error) :
	if error :
		logFileHandle = open( logFileName, "a")
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
		print "=> Le fichier de log est: < " + logFileName + " >.\n"
		exit(rc)

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

def findParameterInEnvironment( environment, parameter, separator ) :
	result = ""
	for assignment in environment.splitlines() :
		if parameter in assignment :
			assignment = re.sub( separator + '+' , separator, assignment ) #Replace multiple occurences of separators by separator
			result = assignment.split( separator )[ 1 ]

			return result

	return result

def myGetEnv( variable ) :
	result = getenv( variable )
	if result is None : result = ""
	return result 

def initDates() :
	global day, month, year, yearMonth, yearMonthDay
	today = datetime.today()
	year = today.strftime('%Y')
	month = today.strftime('%m')
	day = today.strftime('%d')
	yearMonth = today.strftime('%Y%m')
	yearMonthDay = today.strftime('%Y%m%d')

def initLog() :
	funcName = inspect.stack()[0][3]
	initDates()

	global logFileName
	toolsDir = getenv( "toolsDir" )
	if toolsDir and isabs(toolsDir) :
		logBaseDir = toolsDir + os.sep + "log"
	else :
		logBaseDir = dirname(__file__) + os.sep + "log"

	logDir = logBaseDir + os.sep + "log" + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"

	global pid
	pid = str( os.getpid() )

	if not exists(logFileName) :
		printNLogString( "=> Debut de la log du script <" + scriptBaseName + "> pour le " + day + "/" + month + "/" + year + "." )

	printNLogInfo( "Lancement du script < " + scriptBaseName + " > dont le PID est < " + pid + " >." )

def initArgs() :
	parser = argparse.ArgumentParser(description = 'DO NOT USE - WORK IN PROGRESS !')
	parser.add_argument("string", help="String to find in ELSAG Logs.")
	parser.add_argument("lastArgs", nargs='*', help="other optional arguments")

	global scriptBaseName, args
	args = parser.parse_args()
	scriptBaseName = parser.prog

def initScript() :
	funcName = inspect.stack()[0][3]

	global defvareurScript, environment
	defvareurScript = myGetEnv("DEFVAREUR")
	if not defvareurScript :
		print >> stderr , "The environment variable <DEFVAREUR> is not defined."
		exit(1)

	environment = getEnvironmentFromScript( defvareurScript )
	initArgs()
	initLog()
	printNLogInfo( "Continuing function <" + funcName + "> ..." )
	printNLogInfo( "The script < " + scriptBaseName + " > is started the following way:\n[pid=" + pid + "]: " + " ".join(argv) )
	if not exists( args.srcFileName ) : printNLogErrorAndExit( "The sourcefile < " + args.srcFileName + " > does not exists anymore.", -2 )
	printNLogInfo( "Loading the environment variables stored in < " + defvareurScript + " >." )
	setEnvironmentFromString( environment )

def main() :
	initScript()

main()
