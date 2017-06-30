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
from datetime import datetime, date
from time import sleep, strftime, localtime
from pdb import set_trace #To add a breakpoint for PDB debugger
from shutil import move, copy2, Error

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
	parser = ArgumentParser(description = 'DO NOT USE - WORK IN PROGRESS !', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument( "fileList", nargs='*', default=['*.log'], help = "globbing partern of empty files to delete, default is *" )
	parser.add_argument( "-r","--recursive", default = False, action='store_true', help="select files recursively" )
	parser.add_argument( "-d", "--dir", default=".", help="select files from dir." )
	parser.add_argument( "--dstBaseDir", default=".", help="moves to dstBaseDir file tree." )
	parser.add_argument( "-y","--run", default = False, action='store_true', help="run in real mode." )
	parser.add_argument( "-s", "--size", type = int, default=0, help="select with greater size than s bytes." )
	parser.add_argument( "--days", type = int, default=90, help="select files older than n days, default is 90 days." )

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

	if isdir( args.dir ) :
		chdir( args.dir )
	else :
		print >> stderr, "=> This directory " + args.dir + " does not exist."
		exit(2)

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
	global logFile, logHandle
	logFile = logDir + os.sep + splitext( scriptBaseName )[0] + datetime.now().strftime("_%Y%m%d") + ".txt"

	if not exists(logFile) :
		with open(logFile,"a") as logHandle :
			printNLogString( "="*80 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*80 + "\n" )

def initScript() :
	initDates()
	initArgs()
	initLog()
	global dstBaseDir, sameFS, PWD
	sameFS = False
	PWD = getcwd()
	if   os.name == "nt"    :
		if PWD[:2] == args.dstBaseDir[:2] : sameFS = True
		dstBaseDir = args.dstBaseDir + os.sep + PWD[3:]
	elif os.name == "posix" :
		if stat(PWD).st_dev == stat(args.dstBaseDir).st_dev : sameFS = True
		# dstBaseDir = args.dstBaseDir + os.sep + 

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

def dateOfFile( file, strftimeFomat = "%Y%m%d" ) :
	return strftime( strftimeFomat, localtime( getmtime( file ) ) )

def ageOfFile( file ) :
	return date.today() - date.fromtimestamp( getmtime( file ) )

def moveFiles( fileList ) :
	nbFiles = 0
	previous = 0.0
	percentile = 0.0
	totalNumberOfFiles = len( fileList )
	printNLogString( "==> Processing these files ...\n" )
	# printf( "=>   0.0%%" )
	printf( "=>  %4.1f%%", percentile )
	for currentFile in fileList :
		# if basename(currentFile) != basename(logFile) and getsize(currentFile) >= args.size and ageOfFile(currentFile).days > args.days :
		if basename(currentFile) != basename(logFile) :
			# fileYearMonthDay = strftime('%Y%m%d', localtime( getmtime( currentFile ) ) )
			# fileYearMonth = fileYearMonthDay[:-2]
			# fileYear = fileYearMonthDay[:-4]
			destination = dstBaseDir + os.sep + dirname(currentFile)
			if not exists(destination) : makedirs(destination)

			try :
				if sameFS :
					print >> logHandle, "==> Moving file : " + currentFile + " to " + destination + " ..."
					move( currentFile, destination )
				else :
					print >> logHandle, "==> Copying file : " + currentFile + " to " + destination + " ..."
					copy2( currentFile, destination )
			except (Error, WindowsError) as why :
				print >> logHandle, "\n==> ERROR: %s" % why
				print >> stderr, "\n==> ERROR: %s." % why
			else :
				if not sameFS :
					print >> logHandle, "=> Deleting source file : " + currentFile + " ..."
					try :
						remove( currentFile )
					except WindowsError as why :
						print >> logHandle, "\n==> ERROR: %s" % why
						print >> stderr, "\n==> ERROR: %s." % why
					else :
						print >> logHandle, "=> Done."
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
		printNLogError( "=> WARNING: The script < " + scriptBaseName + " > in " + mode + " mode on server < " + platform.node() + startTime.strftime(' > at %X on the %d/%m/%Y') + " for the directory < " + args.dir + " >.\n" )

		printNLogString( "=> Processing directory < " + args.dir + " > ..." )
		printNLogString( "=> regExp = " + regExp + "\n" )
		# nbFiles = 0
		if args.recursive :
			for currDir, subDirs, files in walk('.') :
				begin = datetime.now()
				matchingFileList = [ join(currDir, file) for file in files if isfile(join(currDir, file)) and pattern.search( file ) and getsize( join(currDir, file) ) >= args.size and ageOfFile(join(currDir, file)).days >= args.days ]
				# matchingFileList = []
				# for file in files :
					# if file == "archive_files.txt" : print "=> file = " + file + " is " + str(ageOfFile( join(currDir, file) ).days) + " old."
					# if isfile( join(currDir, file) ) and pattern.search( file ) and getsize( join(currDir, file) ) >= args.size and ageOfFile( join(currDir, file) ).days >= args.days :
						# matchingFileList += [ join(currDir, file) ]

				nbFiles = len(matchingFileList)
				if nbFiles :
					printNLogString( "\n==> It took : " + str(datetime.now()-begin) + " to count " + str( nbFiles ) + " files in subdirectory < " + args.dir+currDir[1:] + " > :\n" )
					if args.run :	nbTotalFiles += moveFiles(matchingFileList)
					else : nbTotalFiles+= nbFiles; printNLogString( "\n".join( matchingFileList ) + "\n" )
				else :
					print >> logHandle, "==> No file matching this pattern was found in subdirectory < " + args.dir+currDir[1:] + " >."
		else :
			matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and pattern.search( name ) and getsize( name ) > args.size and ageOfFile( name ).days >= args.days ]
			nbFiles = len(matchingFileList)
			if nbFiles :
				printNLogString( "\n=> It took : " + str(datetime.now()-startTime) + " to count " + str( nbFiles ) + " files :\n" )
				if args.run :	nbTotalFiles = moveFiles(matchingFileList)
				else : printNLogString( "\n".join( matchingFileList ) + "\n" )
			else :
				printNLogError("=> No file matching this pattern was found in subdirectory < " + getcwd() + " >.")

		if args.run :
			printNLogString( "\n"*3+"=> It took : " + str(datetime.now()-startTime) + " to archive < " + str(nbTotalFiles) +  " > into the directory < " + args.dstBaseDir + " > files for the regExp < " + regExp + " >.\n" )
		elif args.recursive :
			printNLogString( "\n"*2+"=> It took : " + str(datetime.now()-startTime) + " to list < " + str(nbTotalFiles) +  " > files for the regExp < " + regExp + " >.\n" )

		end=datetime.now()
		printNLogString( "\n=> The script < " + scriptBaseName + end.strftime(' > ended at %X on the %d/%m/%Y.') + "\n\n")

	print >> stderr, "=> See the log file: < " + logFile + " >."

main()
