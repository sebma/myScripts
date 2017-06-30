#!/usr/bin/env python
#coding: latin1

import os, sys
from os import listdir, chdir, getcwd, makedirs, stat, getenv, remove
from os.path import exists, splitext, basename, dirname, isfile, isdir, getmtime, isabs
from sys import stdout, stderr, exit, argv
from glob import glob
from time import strftime, localtime
from shutil import move, copy2, Error
import platform
import re
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from datetime import datetime
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

def dateOfFile( file, strftimeFomat = "%Y%m%d" ) :
	return strftime( strftimeFomat, localtime( getmtime( file ) ) )

def initArgs() :
	parser = ArgumentParser( description = 'Reorganize files according to their timestamp.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument("-d", "--dir", default='.', help="select the directory to scan (defaults to .)")
	# parser.add_argument("-r", "--regExp", default='.', help="regular expression to select the files to be moved.")
	parser.add_argument( "-y","--run", default = False, action='store_true', help="run in real mode." )
	parser.add_argument( "-o","--overwrite", default = False, action='store_true', help="overwrite existing files.")
	parser.add_argument("fileList", nargs='*', default=['*.log'], help="globbing pattern to select the files to be hierarchized upon their timestamp.")

	global args, scriptBaseName
	scriptBaseName = parser.prog
	args = parser.parse_args()

	if isdir( args.dir ) : chdir( args.dir )
	else :
		print >> stderr, "=> This directory " + args.dir + " does not exists."
		exit(1)

def initDates() :
	global day, month, year, yearMonth, yearMonthDay, theDate
	today = datetime.today()
	year = today.strftime('%Y')
	month = today.strftime('%m')
	day = today.strftime('%d')
	yearMonth = today.strftime('%Y%m')
	yearMonthDay = today.strftime('%Y%m%d')
	theDate = today.strftime('%d/%m/%Y')

def initScript() :
	initDates()
	initLog()
	global previousDir
	previousDir = getcwd()
	global pattern, regExp
	regExp = "|".join( args.fileList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
	regExp += "$"
	pattern = re.compile(regExp, re.I)
	global startTime
	startTime = datetime.now()

	global mode
	if args.run : mode = "REAL"
	else : mode = "SIMULATION"

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

def main() :
	initScript()

	global logHandle
	with open( logFile , 'a' ) as logHandle :
		printNLogError( "=> Starting the script < " + scriptBaseName + " > the following way : " + " ".join(argv) + "\n" )
		printNLogError( "=> WARNING: The script < " + scriptBaseName + " > is running in " + mode + " mode on server < " + platform.node() + startTime.strftime(' > at %X on the %d/%m/%Y') + " for the directory < " + args.dir + " >.\n" )

		printNLogString( "=> Counting the files to be processed in the directory < " + args.dir + " > ..." )
		printNLogString( "=> regExp = " + regExp )
		nbFiles = 0
		previous = 0.0
		matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and pattern.search( name ) and dateOfFile(name, '%Y%m%d') != yearMonthDay ]

		totalNumberOfFiles = len( matchingFileList )
		if totalNumberOfFiles :
			printNLogString( "\n=> It took : " + str(datetime.now()-startTime) + " to count "+str( totalNumberOfFiles )+" files.\n" )
			if args.run :
				printf( "=>   0.0%%" )
				for fileBaseName in matchingFileList :
						fileYearMonthDay = strftime('%Y%m%d', localtime( getmtime( fileBaseName ) ) )
						fileYearMonth = fileYearMonthDay[:-2]
						fileYear = fileYearMonthDay[:-4]
						dstDir = fileYear + os.sep + fileYearMonth + os.sep + fileYearMonthDay
						if not exists( dstDir ) : makedirs( dstDir )

						destination = dstDir + os.sep + fileBaseName
						print >> logHandle, "=> Moving < " + fileBaseName + " > into < " + destination + " ..."

						if exists( destination ) and args.overwrite :
							printNLogString( "=> INFO: Overwriting file < " + destination + " > ..." )
							remove( destination )

						try :
							move( fileBaseName, destination )
						except (Error, WindowsError) as why : 
							printNLogError( "\n=> ERROR: %s" % why )
						else :
							nbFiles+=1

						percentile = nbFiles *100.0/totalNumberOfFiles
						if percentile - previous > 0.1 :
							printf( "\b" * 6 + "%4.1f%%", percentile ) #Pour faire varier le pourcentage sur la meme ligne
							previous = percentile
			else : print "\n".join( matchingFileList ) + "\n"

			end=datetime.now()
			if args.run :
				printNLogString( "\n=> It took : " + str(end-startTime) + " to move < " + str(nbFiles) +  " > files.\n" )
		else :
			printNLogError("\n=> No file matching this pattern was found in subdirectory < " + getcwd() + " >.")

		end=datetime.now()
		printNLogString( "\n=> The script < " + scriptBaseName + end.strftime(' > ended at %X on the %d/%m/%Y.') + "\n\n")

	print >> stderr, "=> See the log file: < " + logFile + " >."
	chdir( previousDir )

main()
