#!/usr/bin/env python
#coding: latin1

import time
import argparse
import os
from os import getenv, makedirs
from os.path import exists, splitext, dirname, isabs
import inspect
import platform
from sys import stderr
from datetime import datetime
from signal import signal, SIGINT
from pdb import set_trace #To add a breakpoint for PDB debugger
from subprocess import Popen, PIPE, call

def printStringToStdoutAndFile(fileName, string) :
	print string
	if fileName :
		with open( fileName, "a" ) as fileHandle :
			print >> fileHandle, string

def printStringToStderrAndFile(fileName, string) :
	print >> stderr, string
	if fileName :
		with open( fileName, "a" ) as fileHandle :
			print >> fileHandle, string

def signal_handler(signal, frame):
	printStringToStdoutAndFile(args.output, 'You pressed Ctrl+C!')

	endScript(1)

def initArgs() :
	parser = argparse.ArgumentParser(description = 'run programs and summarize system resource usage')
	parser.add_argument( "-a", "--append", default = False, action='store_true', help="Append the resource use information to the output file instead of overwriting it.\nThis option is only useful with the `-o' or `--output' option." )
	parser.add_argument( "-o", "--output", help="Write the resource use statistics to FILE instead of to the standard error stream." )
	parser.add_argument( "-L", "--log", help="print and log all actions done.", action='store_true', default = False )
	parser.add_argument( "command", type=str, nargs='+', help = "run the program COMMAND with any given arguments" )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

	if args.append and not args.output : parser.print_usage(stderr) ; exit(-1)

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
		# printNLogString( "=> Starting logging of script <" + scriptBaseName + "> on server <" + platform.node() + "> for the " + day + "/" + month + "/" + year + "." )
	else :
		logFileHandle = open( logFileName, "a" )

	progPID = str( os.getpid() )
	printNLogInfo( "Starting of script < " + scriptBaseName + " > which PID is < " + progPID + " >." )

def initScript() :
	funcName = inspect.stack()[0][3]
	initArgs()
	initDates()
	global progPID
	progPID = str( os.getpid() )
	if args.log :
		initLog()
		printNLogInfo( "=> Starting the script < " + scriptBaseName + " > the following way : " + " ".join(argv) + "\n" )

	global begin
	begin=datetime.now()

def runCommandAndReturnOutput(myCommand) :
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def runCommand(myCommand) :
	print >> stderr, "=> Running the command : " + myCommand

	# retCode = call( myCommand, shell = True )
	myProcess = Popen( myCommand, shell = True )
	myProcess.communicate()
	retCode = myProcess.returncode

	return retCode

def endScript(retCode) :
	end = datetime.now()
	printStringToStderrAndFile( args.output, "\n=> The script < " + scriptBaseName + end.strftime(' > ended at %X on the %d/%m/%Y.') + "\n")
	printStringToStderrAndFile( args.output, "=> It took : " + str(end-begin) + " to run the command < "+ " ".join( args.command ) +" > on server < " + platform.node() + " >.\n" )

	exit(retCode)

def main() :
	# retCode = 0
	initScript()
	mode = "w"
	if args.append : mode = "a"
	signal(SIGINT, signal_handler)
	print >> stderr, "=> INFO: Running the command: " + " ".join( args.command ) + " ..."
	retCode = call( " ".join( args.command ) )

	endScript( retCode )

main()
