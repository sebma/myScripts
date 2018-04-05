#!/usr/bin/env python
#coding: latin1

import argparse
import os
from os import getcwd, chdir, makedirs, stat, utime, getenv, remove
from os.path import exists, basename, splitext, getmtime, abspath, isfile
from time import strftime, localtime, mktime
from sys import argv, stdout, stderr, exit
from shutil import copy2, Error
from datetime import datetime
import inspect
from zipfile import ZipFile, BadZipfile
from hashlib import md5, sha1, sha224, sha256, sha384, sha512
from pdb import set_trace #To add a breakpoint for PDB debugger

def printNLogString(string) :
	print string
	if logFileHandle != stdout : print >> logFileHandle, string

def printNLogInfo(message) :
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		message = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	printNLogString( message )

def printNLogError(error) :
	if error :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		error = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error
		print >> stderr, error
		print >> logFileHandle, error

def printNLogErrorAndExit(error, rc) :
	if error :
		printNLogError(error)
		printNLogError( "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n" )
		print >>stderr, "=> Le fichier de log est: < " + logFileName + ">.\n"
		logFileHandle.close()
		exit(rc)

def calcChecksum(filename, method=1) :
	fileHandle = open(filename, "rb")
	if   method == 5  : h = md5()
	elif method == 1 : h = sha1()
	elif method == 224 : h = sha224()
	elif method == 256 : h = sha256()
	elif method == 384 : h = sha384()
	elif method == 512 : h = sha512()
	else : printNLogErrorAndExit( "Unknown  algorithm.", 2)

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	while True:
		data = fileHandle.read(4*1024*1024)
		if not data: break
		h.update(data)

	hashed = h.hexdigest()
	fileHandle.close()
	return hashed

def readZIPFile(zipFileName) :
	if not exists (zipFileName) : printNLogErrorAndExit( "The file " + zipFileName + " does not exist.", -2 )

	try:
		with ZipFile(zipFileName) as zipFile :
			list = zipFile.namelist()

		zipFileList = []
		for item in list :
			if not item.endswith( "/" ) :
				zipFileList.append(item)

		return zipFileList
	except BadZipfile as e:
		printNLogErrorAndExit( str(e), -3 )

def backupFile(file) :
	if os.name == "nt" : file = file.replace( "/", os.sep )
	fileYearMonthDay = strftime('%Y%m%d_%HH%M', localtime( stat( file ).st_mtime ) )
	backup = splitext( file )[0] + "_" + fileYearMonthDay + splitext( file )[1]
	try :
		printNLogInfo( "The file < " + file + " > already exists, saving a copy to < " + backup + " > ..." )
		copy2( file, backup )
	except Error as e :
		printNLogErrorAndExit( str(e), -4 )

def zipExtract( zipFileName, elem, dstDir="." ) :
	with ZipFile(zipFileName) as zipFile :
			dateTimeTuple = zipFile.getinfo( elem ).date_time
			newDateTime = datetime( *dateTimeTuple )
			zipFile.extract( elem, dstDir )
			if dstDir != tmpDir : print "=> unzipping file = " + elem
			utime( dstDir+os.sep+elem, ( 
				stat( dstDir+os.sep+elem ).st_atime,
				mktime( newDateTime.timetuple() )
				)
			)

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
	logBaseDir = getenv( "toolsDir" ) + os.sep + "log"
	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)

	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"
	if logFileName :
		logFileHandle = open( logFileName, "a" )
	else :
		logFileHandle = stdout

	if not exists(logFileName) :
		printNLogString( "=> Debut de la log du script <" + scriptBaseName + "> pour le " + day + "/" + month + "/" + year + "." )

	global pid
	pid = str( os.getpid() )
	printNLogInfo( "Lancement du script < " + scriptBaseName + " > dont le PID est < " + pid + " >." )

def initArgs() :
	parser = argparse.ArgumentParser()
	parser.add_argument( "zipfile", help="zip file name to extract." )
	parser.add_argument( "-d", "--exdir", help="extract files into exdir.", default="." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	try :    args = parser.parse_args()
	except :
		print >> stderr, "\n" + parser.format_help()
		exit(-1)


def initScript() :
	funcName = inspect.stack()[0][3]
	global tmpDir
	tmpDir = getenv("TMP")
	initArgs()
	initLog()
	printNLogInfo( "The arguments passed to < " + scriptBaseName + " > are:\n" + str(argv[1:]) )
	if not exists( args.zipfile ) : printNLogErrorAndExit( "The sourcefile < " + args.zipfile + " > does not exists anymore.", -2 )

def isNewer( file1, file2 ) :
	return getmtime( file1 ) < getmtime( file2 )

def isDifferent( file1, file2 ) :
	sig1 = calcChecksum(file1)
	sig2 = calcChecksum(file2)
	return sig1 != sig2

def cleanExit( retCode ) :
	logFileHandle.close()
	exit( retCode )

def main() :
	retCode = 0
	initScript()
	args.zipfile = abspath( args.zipfile ) #Le fichier zip doit etre accessible quel que soit le repertoire ou on est
	zipFileList = readZIPFile( args.zipfile )
	if not exists( args.exdir ) : makedirs( args.exdir )
	chdir( args.exdir ) #On travaille en relatif
	for file in zipFileList :
		if exists( file ) :
			zipExtract( args.zipfile, file, tmpDir )
			if isNewer( file, tmpDir + os.sep + file ) and isDifferent( file, tmpDir + os.sep + file ) :
				backupFile(file)
				zipExtract( args.zipfile, file, args.exdir )
			remove( tmpDir + os.sep + file )
		else :
			zipExtract( args.zipfile, file, args.exdir )
	print

	printNLogInfo( "FIN du script: < " + scriptBaseName + " > avec le code de retour : <" + str( retCode ) + ">.\n" )

	if logFileName :
		print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"

	exit( retCode )

main()
