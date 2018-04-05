#!/usr/bin/env python
#coding: latin1

import argparse
import os
from os import getcwd, chdir, makedirs, stat, utime
from os.path import exists, basename, splitext
from time import strftime, localtime
from sys import argv, stderr, exit
from shutil import copy2, Error
import datetime
import inspect
from zipfile import ZipFile, BadZipfile

def isUnixScript(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.read() :
		print >> stderr, "=> ERROR: You must convert the script < " + fileName + " > to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def printNLogString(string) :
	logFileHandle = open( logFileName, "a" )

	print >> logFileHandle, string
	print string

	logFileHandle.close()

def printNLogInfo(message) :
	logFileHandle = open( logFileName, "a" )
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.datetime.now().strftime('%H:%M:%S') + str(datetime.datetime.now().microsecond)
		timestamp = str(datetime.datetime.now())[11:23]
		message = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	print >> logFileHandle, message
	logFileHandle.close()

def readZIPFile(zipFileName) :
	if not exists (zipFileName) : printNLogError( "The file " + zipFileName + " does not exist." )

	try:
		with ZipFile(zipFileName) as zipFile :
			zipFileList = zipFile.namelist()

		return zipFileList
	except BadZipfile as e:
		printNLogErrorAndExit( str(e), -3 )

def zipExtract( zipFileName ) :
	with ZipFile(zipFileName) as zipFile :
		for currentFile in zipFile.namelist() :
			dateTimeTuple = zipFile.getinfo( currentFile ).date_time
			newDateTime = datetime.datetime( *dateTimeTuple )
			zipFile.extract( currentFile )
			utime( currentFile, ( 
				stat( currentFile ).st_atime,
				mktime( newDateTime.timetuple() )
				)
			)

def printNLogError(error) :
	if error :
		logFileHandle = open( logFileName, "a")
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.datetime.now().strftime('%H:%M:%S') + str(datetime.datetime.now().microsecond)
		timestamp = str(datetime.datetime.now())[11:23]
		error = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error
		print >> stderr, error
		print >> logFileHandle, error
		logFileHandle.close()

def printNLogErrorAndExit(error, rc) :
	if error :
		printNLogError(error)
		printNLogError( "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n" )
		print "=> Le fichier de log est: < " + logFileName + ">.\n"
		exit(rc)

def initDates() :
	global day, month, year, yearMonth, yearMonthDay
	today = datetime.date.today()
	year = today.strftime('%Y')
	month = today.strftime('%m')
	day = today.strftime('%d')
	yearMonth = today.strftime('%Y%m')
	yearMonthDay = today.strftime('%Y%m%d')

def initLog() :
	funcName = inspect.stack()[0][3]
	initDates()

	global logFileName
	logBaseDir = getcwd()
	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)

	global scriptBaseName
	scriptBaseName = basename(__file__)
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"
	if not exists(logFileName) :
		printNLogString( "=> Debut de la log du script <" + scriptBaseName + "> pour le " + day + "/" + month + "/" + year + "." )

	global pid
	pid = str( os.getpid() )
	printNLogInfo( "Lancement du script < " + scriptBaseName + " > dont le PID est < " + pid + " >." )


def initArgs() :
	parser = argparse.ArgumentParser()
	parser.add_argument( "-z", "--zipfile", help="file name", required=True )

	global args
	try :    args = parser.parse_args()
	except : printNLogErrorAndExit( "\n" + parser.format_help(), -1 )

	printNLogInfo( "The arguments passed to < " + scriptBaseName + " > are:\n" + str(argv[1:]) )
	if not exists( args.zipfile ) : printNLogErrorAndExit( "The sourcefile < " + args.zipfile + " > does not exists anymore.", -2 )

def initScript() :
	funcName = inspect.stack()[0][3]
	isUnixScript(__file__)
	initLog()
	initArgs()

def backupFile(file) :
	fileYearMonthDay = strftime('%Y%m%d', localtime( stat( file ).st_mtime ) )
	backup = splitext( file )[0] + "_" + fileYearMonthDay + splitext( file )[1]
	print "=> Backup file = " + backup
	try :
		print "=> Backing up file < " + file + " > to < " + backup + " > ..."
		copy2( file, backup )
	except Error as e :
		printNLogErrorAndExit( str(e), -4)

def main() :
	retCode = 0
	initScript()

	zipFileList = readZIPFile( args.zipfile )
	with ZipFile(args.zipfile ) as zipFile :
		for file in zipFileList :
			print "=> file = " + file
			if exists( file ) : backupFile(file)
			zipFile.extract( "sed" )
	print
#	print "=> Extracting all the files ..."
	#with ZipFile(args.zipfile ) as zipFile : zipFile.extractall( os.sep )

	chdir( os.sep )

	printNLogInfo( "FIN du script: < " + __file__ + " > avec le code de retour : <" + str( retCode ) + ">.\n" )

	print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"

	exit( retCode )

main()
