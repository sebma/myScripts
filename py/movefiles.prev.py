#!/usr/bin/env python
#coding: latin1

import os
from os import getenv, chdir, makedirs
from os.path import dirname, exists, splitext
from sys import argv, stderr, exit
from datetime import datetime
import platform
import inspect
from argparse import ArgumentParser
from glob import glob #Filename Globbing patterns
from pdb import set_trace #To add a breakpoint for PDB debugger
from shutil import move, Error

def isUnixScript(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.read() :
		print >> stderr, "=> ERROR: You must convert the script < " + fileName + " > to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def printNLogString(string) :
	logFileHandle = open( logFileName, "a")

	print >> logFileHandle, string
	print string

	logFileHandle.close()

def printNLogErrorString(string) :
	logFileHandle = open( logFileName, "a")

	if not args.quiet : print >> stderr, string
	if args.log : print >> logFileHandle, string

	logFileHandle.close()

def printNLogInfo(message) :
	logFileHandle = open( logFileName, "a")
	if message :
		callerFunctionName = inspect.stack()[1][3]
		if callerFunctionName == "<module>" : callerFunctionName = "main"

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		message = timestamp + " - [" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	print >> logFileHandle, message
	logFileHandle.close()

def printNLogError(error) :
	if error :
		(frame, filename, line_number, callerFunctionName, lines, index) = inspect.stack()[1]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]

		error = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + error
		printNLogErrorString( error )

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='+', help = "filename globbing partern list to process." )
	parser.add_argument( "-sd", "--srcDir", help="source directory (default is current).", default = "." )
	parser.add_argument( "-dd", "--dstDir", help="destination directory.", required=True)
	parser.add_argument( "-n", "--number", type=int, help="number of files to move (default is 10).", default=10 )
	parser.add_argument( "-L", "--log", help="print and log all actions done.", action='store_true', default = False )
	parser.add_argument( "-q", "--quiet", help="quiet mode", action='store_true', default = False )
	parser.add_argument( "-y","--run", default = False, action='store_true', help="run in real mode." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

	# print "=> args = " + " ".join(argv)
	# set_trace()

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
	global logFileName

	logBaseDir = toolsDir + os.sep + "log"
	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay

	if not exists( logDir ) : makedirs( logDir )
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"

	if not exists(logFileName) :
		printNLogString( "="*80 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*80 + "\n" )

def initScript() :
	isUnixScript(__file__)
	initArgs()
	initDates()

	if not exists( args.dstDir+os.sep ) : makedirs( args.dstDir )
	global toolsDir, pid, startTime, mode
	toolsDir = getenv( "toolsDir" )
	pid = str( os.getpid() )

	if args.run : mode = "REAL"
	else : mode = "SIMULATION"

	startTime = datetime.now()
	initLog()

def main() :
	initScript()
	printNLogInfo( "STARTING script: < " + __file__ + " >." )

	nb, code = 0, 0
	printNLogErrorString( "=> Starting the script < " + scriptBaseName + " > the following way :\n\n" + " ".join(argv) + "\n" )
	printNLogErrorString( "=> WARNING: The script < " + scriptBaseName + " > is running in " + mode + " mode on server < " + platform.node() + startTime.strftime(' > at %X on the %d/%m/%Y') + " for the directory < " + args.srcDir + " >.\n" )

	if args.srcDir != "." : chdir(args.srcDir)
	for currentGlobbingPattern in args.fileList :
		fileList = glob( currentGlobbingPattern )[0:args.number]
		printNLogInfo( "Found " + str( len(fileList) ) + " files matching pattern < " + currentGlobbingPattern + " > to process :\n" )
		for fileBaseName in fileList :
			try :
				if args.run : move(fileBaseName, args.dstDir + os.sep)
			except (Error, WindowsError, IOError) as why :
				printNLogError( "%s." % why )
			else :
				printNLogString( fileBaseName + " -> " + args.dstDir + os.sep )
				nb+=1

	printNLogString("")
	if args.run : printNLogString( str(nb) + " files were processed.\n" )

	printNLogInfo( "END of script: < " + __file__ + " >.\n" )

	print >> stderr, "=> La log du script < " + scriptBaseName + " > est: < " + logFileName + " >.\n"

main()
