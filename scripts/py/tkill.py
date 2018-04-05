#!/usr/bin/env python
#coding: latin1

import argparse
import os
from os import getenv, makedirs, kill
from os.path import exists, splitext, dirname, isabs
import re
import inspect
import platform
from sys import argv
from sys import stderr
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger
from subprocess import Popen, check_output, PIPE, call

def printNLogString(string) :
	print string
	if args.log : print >> logFileHandle, string

def printNLogErrorString(string) :
	print >> stderr, string
	if args.log : print >> logFileHandle, string

def printNLogInfo(message) :
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		message = timestamp + " - [" + progPID + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	printNLogString( message )

def initArgs() :
	parser = argparse.ArgumentParser(description='Kill processes according to a given pattern.')
	parser.add_argument( "-L", "--log", help="print and log all actions done.", action='store_true', default = False )
	parser.add_argument( "-f", "--force", help="Force process kill", action='store_true', default = False )
	parser.add_argument( "-y", "--run", help="run in real mode.", action='store_true', default = False )
	parser.add_argument( "-p", "--pid", type=int, help="pid of process to kill" )
	parser.add_argument( "patternList", nargs='+', help = "Search for PATTERN in each FILE or standard input", default = '*' )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

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

	global logFileName, logFileHandle
	toolsDir = getenv( "toolsDir" )
	if toolsDir and isabs(toolsDir) :
		logBaseDir = toolsDir + os.sep + "log"
	else :
		logBaseDir = dirname(__file__) + os.sep + "log"

	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)

	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"

	if not exists(logFileName) :
		logFileHandle = open( logFileName, "w" )
		printNLogString( "=> Starting logging of script <" + scriptBaseName + "> on server <" + platform.node() + "> for the " + day + "/" + month + "/" + year + "." )
	else :
		logFileHandle = open( logFileName, "a" )

	progPID = str( os.getpid() )
	printNLogInfo( "Starting of script < " + scriptBaseName + " > which PID is < " + progPID + " >." )

def initScript() :
	funcName = inspect.stack()[0][3]
	initArgs()
	global progPID
	progPID = str( os.getpid() )
	if args.log :
		initLog()
		printNLogInfo( "=> Starting the script < " + scriptBaseName + " > the following way : " + " ".join(argv) + "\n" )

	regExp = "|".join( args.patternList ).replace('\\', '/').replace('.','\.').replace('?', '.').replace('*', '.*').replace('|', '$|')
	# print "=> regExp = " + regExp

	global pattern
	pattern = re.compile(regExp, re.I)

def runCommandAndReturnOutput(myCommand) :
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def killProcess(pID) :
	if   os.name == "nt"    :
		if args.force :
			retCode = call( "taskkill -t -f -pid " + pID )
		else :
			retCode = call( "taskkill -t -pid " + pID )
	elif os.name == "posix" :
		if args.force :
			retCode = call( "kill -9 " + pID )
		else :
			retCode = call( "kill " + pID )
	if retCode == 0 and os.name == "posix" : printNLogString( "=> INFO: Successfully killed process of pid " + pID )
	return retCode

def killProcessesFromPattern( pattern ) :
	if   os.name == "nt"    :
		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "tlist -c" )
		if retCode :
			printNLogErrorString( stderrStr + "\n" + "=> ERROR: The <tlist> tool is not installed." )
			return retCode
	elif os.name == "posix" :
		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "ps -elf" )

	if os.name == "nt" :
		i = 0
		pidList, processList = [],[]
		for line in stdoutStr.splitlines() :
			if i > 3 :
				if i % 2 :
					processList.append(" ".join(line.split()[2:]).replace("\\","/"))
				else :
					pidList.append(line.split()[0])
			i += 1

		i = 0
		for process in processList :
			if pattern.search( process ) and pidList[i] != progPID :
				printNLogString( "=> INFO: Matching process found: < " + process + " > of pid < " + pidList[i] + " >." )
				if args.run : retCode += killProcess(pidList[i])
			i += 1

	return retCode

def main() :
	retCode = 0
	initScript()
	if args.pid :
		retCode = killProcess(args.pid)
	else :
		retCode = killProcessesFromPattern(pattern)
	if args.log : print >> stderr, "\n=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"
	exit( retCode )

main()
