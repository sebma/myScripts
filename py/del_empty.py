#!/usr/bin/env python
#coding: latin1

import os, platform
from os import chdir, walk, remove, stat, getenv, makedirs, listdir, getcwd
from os.path import basename, dirname, isdir, isfile, join, exists, splitext, abspath, isabs
from os.path import getsize, getmtime
from sys import stderr, exit, argv
import re
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from datetime import datetime
from time import sleep, strftime, localtime
from pdb import set_trace #To add a breakpoint for PDB debugger

def printNLogString( string ) :
	print >> logHandle, string
	print string

def printNLogError( error ) :
	print >> logHandle, error
	print >> stderr, error

def printf(format, *args) : 
	print format % args,
	if os.name == "posix" : stdout.flush()

def initArgs() :
	parser = ArgumentParser(description = 'Remove recursively small or empty files.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument( "fileList", nargs='*', default=['*.log'], help = "globbing partern of empty files to delete, default is *" )
	parser.add_argument( "-r","--recursive", default = False, action='store_true', help="list subdirectories recursively" )
	parser.add_argument( "-d", "--dir", default=".", help="list files from dir." )
	parser.add_argument( "-y","--run", default = False, action='store_true', help="run in real mode." )
	parser.add_argument( "-s", "--size", type = int, default=0, help="list files from dir." )

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

	if isdir( args.dir ) : chdir( args.dir )
	else :
		print >> stderr, "=> This directory " + args.dir + " does not exist."
		exit(1)

def dateOfFile( file, strftimeFomat = "%Y%m%d" ) :
	return strftime( strftimeFomat, localtime( getmtime( file ) ) )

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
	toolsDir = getenv( "toolsDir" )
	if toolsDir and isabs(toolsDir) :
		logBaseDir = toolsDir + os.sep + "log"
	else :
		logBaseDir = dirname(__file__) + os.sep + "log"

	logDir = logBaseDir + os.sep + "log" + os.sep + datetime.now().strftime( "%Y" + os.sep + "%Y%m" + os.sep + "%Y%m%d" )
	if not exists( logDir ) : makedirs( logDir )
	initArgs()
	global logFile, logHandle
	logFile = logDir + os.sep + splitext( scriptBaseName )[0] + datetime.now().strftime("_%Y%m%d") + ".txt"
	print >> stderr, "=> The log file will be : < " + logFile + " >.\n"

	if not exists(logFile) :
		with open(logFile,"a") as logHandle :
			printNLogString( "="*80 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*80 + "\n" )

def initScript() :
	initDates()
	initLog()
	initArgs()

	global nbTotalFiles
	nbTotalFiles = 0

	global pattern, regExp
	regExp = "|".join( args.fileList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
	regExp += "$"
	pattern = re.compile(regExp, re.I)
	global startTime
	startTime = datetime.now()

	global mode
	if args.run : mode = "REAL"
	else : mode = "SIMULATION"

def delEmpty( fileList ) :
	nbFiles = 0
	previous = 0.0
	totalNumberOfFiles = len( fileList )
	printNLogString( "==> Processing these files ...\n" )
	printf( "=>   0.0%%" )
	for currentFile in fileList :
		if basename(currentFile) != basename(logFile) and dateOfFile(currentFile, '%Y%m%d') != yearMonthDay and getsize(currentFile) == args.size :
			print >> logHandle, "==> Deleting file : " + currentFile + " ..."

			try :
				remove( currentFile )
			except WindowsError as why :
				print >> logHandle, "\n==> ERROR: %s" % why
				print >> stderr, "\n==> ERROR: %s." % why
			else :
				nbFiles+=1

			percentile = nbFiles *100.0/totalNumberOfFiles
			if percentile - previous > 0.1 :
				printf( "\b" * 6 + "%4.1f%%", percentile ) #Pour faire varier le pourcentage sur la meme ligne
				previous = percentile

	return nbFiles

def main() :
	initScript()
	global logHandle

	nbTotalFiles = 0
	# set_trace()
	with open( logFile , 'a' ) as logHandle :
		printNLogError( "=> Starting the script < " + scriptBaseName + " > the following way : " + " ".join(argv) + "\n" )
		printNLogError( "=> WARNING: The script < " + scriptBaseName + " > is running in " + mode + " mode on server < " + platform.node() + startTime.strftime(' > at %X on the %d/%m/%Y') + " for the directory < " + args.dir + " >.\n" )

		printNLogString( "=> Processing directory < " + args.dir + " > ..." )
		printNLogString( "=> regExp = " + regExp + "\n" )
		# nbFiles = 0
		if args.recursive :
			global root
			for root, dirs, files in walk('.') :
				begin = datetime.now()
				matchingFileList = [ join(root, file) for file in files if isfile(join(root, file)) and pattern.search( file ) and getsize( join(root, file) ) == args.size  and dateOfFile(join(root, file), '%Y%m%d') != yearMonthDay ]
				nbFiles = len(matchingFileList)
				if nbFiles :
					printNLogString( "\n=> It took : " + str(datetime.now()-begin) + " to count " + str( nbFiles ) + " files in subdirectory < " + args.dir+root[1:] + " >.\n" )
					if args.run :	nbTotalFiles += delEmpty(matchingFileList)
					else : print "\n".join( matchingFileList ) + "\n"
				else :
					print >> logHandle, "=> No file matching this pattern was found in subdirectory < " + args.dir+root[1:] + " >."
		else :
			matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and pattern.search( name ) and getsize( name ) == args.size and dateOfFile(name, '%Y%m%d') != yearMonthDay ]
			nbFiles = len(matchingFileList)
			if nbFiles :
				printNLogString( "\n=> It took : " + str(datetime.now()-startTime) + " to count " + str( nbFiles ) + " files.\n" )
				if args.run :	nbTotalFiles = delEmpty(matchingFileList)
				else : print "\n".join( matchingFileList ) + "\n"
			else :
				printNLogError("=> No file matching this pattern was found in subdirectory < " + getcwd() + " >.")

		if args.run :
			printNLogString( "\n=> It took : " + str(datetime.now()-startTime) + " to delete < " + str(nbTotalFiles) +  " > empty files.\n" )

		end=datetime.now()
		printNLogString( "\n=> The script < " + scriptBaseName + end.strftime(' > ended at %X on the %d/%m/%Y.') + "\n\n")

	print >> stderr, "=> See the log file: < " + logFile + " >."

main()
