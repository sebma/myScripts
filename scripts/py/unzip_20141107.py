#!/usr/bin/env python
#coding: latin1

import argparse
import os
from os import getcwd, chdir, makedirs, stat, utime, getenv, rmdir, listdir, remove
from os.path import exists, basename, dirname, splitext, getmtime, getatime, abspath, isfile, isabs
import re
import inspect
import platform
from time import strftime, localtime, mktime
from sys import argv, stdout, stderr, exit, exc_info
from shutil import copy2, move, rmtree, Error
from datetime import datetime
from zipfile import ZipFile, BadZipfile
from hashlib import md5, sha1, sha224, sha256, sha384, sha512
from pdb import set_trace #To add a breakpoint for PDB debugger
from subprocess import Popen, check_output, PIPE, call
from collections import OrderedDict

def printNLogString(string) :
	if not args.quiet : print string
	if args.log : print >> logFileHandle, string

def printNLogErrorString(string) :
	if not args.quiet : print >> stderr, string
	if args.log : print >> logFileHandle, string

def printNLogInfo(message) :
	if message :
		(frame, filename, line_number, callerFunctionName, lines, index) = inspect.stack()[1]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]

		message = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message
		printNLogString( message )

def printNLogError(error) :
	if error :
		(frame, filename, line_number, callerFunctionName, lines, index) = inspect.stack()[1]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]

		error = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + error
		printNLogErrorString( error )

def printNLogErrorAndExit(errorMessage, rc) :
	if errorMessage :
		(frame, filename, line_number, callerFunctionName, lines, index) = inspect.stack()[1]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]

		errorMessage = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + errorMessage
		exitMessage  = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n"
		printNLogErrorString( errorMessage + "\n" + exitMessage )

		if args.log :
			print >> stderr, "=> Le fichier de log est: < " + logFileName + ">.\n"
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
	else : print >> stderr, "Unknown  algorithm."; exit( 2)

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	while True:
		data = fileHandle.read(4*1024*1024)
		if not data: break
		h.update(data)

	hashed = h.hexdigest()
	fileHandle.close()
	return hashed

def dateOfFile( file, strftimeFomat = "%Y%m%d" ) :
	return strftime( strftimeFomat, localtime( getmtime( file ) ) )

def backupFile(file) :
	if os.name == "nt" : file = file.replace( "/", os.sep )
	# fileYearMonthDay = strftime('%Y%m%d_%HH%M', localtime( stat( file ).st_mtime ) )
	fileYearMonthDay = dateOfFile(file, '%Y%m%d_%HH%M' )
	backup = splitext( file )[0] + "_" + fileYearMonthDay + splitext( file )[1]
	try :
		printNLogString( "The file < " + abspath(file) + " > already exists, saving a copy to < " + args.dir.replace('/',os.sep) + os.sep + backup + " > ..." )
		copy2( file, backup )
	except Error as why :
		print >> stderr, str(why); exit( -4 )

def readZIPFile(zipFileName) :
	if not exists(zipFileName) : print >> stderr, "The file " + zipFileName + " does not exist."; exit( -2 )

	try:
		with ZipFile(zipFileName) as zipFile :
			myList = zipFile.namelist()

		printNLogString( "Archive:  " + zipFileName )
		zipFileList = []
		zipDirList = []
		for item in myList :
			if not item.endswith( "/" ) and pattern.search( item ) :
				zipFileList.append(item)
				zipDirList.append(dirname(item))

		zipDirList = list(OrderedDict.fromkeys(zipDirList)) #Pour supprimer les doublons

		return sorted(zipFileList, key=lambda s: s.lower()), sorted(zipDirList, key=lambda s: s.lower(), reverse=True)
	except BadZipfile as why:
		print >> stderr, str(why); exit( -3 )

def zipExtractFile( zipFileName, elem, dstDir="." ) :
	with ZipFile(zipFileName) as zipFile :
		dateTimeTuple = zipFile.getinfo( elem ).date_time
		newDateTime = datetime( *dateTimeTuple )
		zipFile.extract( elem, dstDir )
		if dstDir != tmpDir :
			if args.dir == "/" : print "  inflating: " + "/" + elem
			else : print "  inflating: " + args.dir + "/" + elem
		utime( dstDir+os.sep+elem,
			( 
				getatime( dstDir+os.sep+elem ),
				mktime( newDateTime.timetuple() )
			)
		)

def zipExtractAll( zipFileName, dstDir="." ) :
	# print >> stderr, "=> Extracting all files to < " + dstDir + " > to preserve the timestamps."
	fileList, dirList = readZIPFile(zipFileName)
	with ZipFile(zipFileName) as zipFile :
		for elem in fileList :
			dateTimeTuple = zipFile.getinfo( elem ).date_time
			newDateTime = datetime( *dateTimeTuple )
			zipFile.extract( elem, dstDir )
			utime( dstDir+os.sep+elem,
				( 
					getatime( dstDir+os.sep+elem ),
					mktime( newDateTime.timetuple() )
				)
			)

	return fileList, dirList

def initArgs() :
	parser = argparse.ArgumentParser(description='list, test and extract compressed files in a ZIP archive')
	parser.add_argument( "zipfile", nargs='?', help="zip file name to extract." )
	parser.add_argument( "-d", "--dir", help="extract files into dir.", default="." )
	parser.add_argument( "-o", "--overwrite", help="overwrite files WITHOUT prompting", action='store_true', default = False )
	parser.add_argument( "-q", "--quiet", help="quiet mode", action='store_true', default = False )
	parser.add_argument( "-nb", "--no-backup", help="don't backup existing files", action='store_true', default = False )
	parser.add_argument( "-j", "--junk-paths", help="junk paths (do not make directories)", action='store_true', default = False )
	parser.add_argument( "-l", "--list", help="list files (short format)", action='store_true', default = False )
	parser.add_argument( "-k", "--kill", help="kill processes before unzipping new binaries", action='store_true', default = False )
	parser.add_argument( "-L", "--log", help="print and log all actions done.", action='store_true', default = False )
	parser.add_argument( "-r", "--restore", nargs='+', help="restore the files from their backup according to the log." )
	parser.add_argument( "fileList", nargs='*', help = "Search for PATTERN in each FILE or standard input", default = '*' )

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

	if len(args.dir) == 0 : args.dir = "."
	else : 
		if os.name == "nt" : args.dir = args.dir.replace( os.sep, '/' )

	if args.restore :
		if args.log :
			print >> stderr, "=> ERROR: The logging option cannot be used with the restore mode.\n"
			parser.print_usage(stderr)
			exit(1)
	else :
		if not args.zipfile :
			parser.print_usage(stderr)
			exit(2)

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

	logFileName = logDir + os.sep + "Delivery" + "_" + yearMonthDay + ".log"

	if not exists(logFileName) :
		logFileHandle = open( logFileName, "w" )
		printNLogString( "=> Starting logging of script <" + scriptBaseName + "> on server <" + platform.node() + "> for the " + day + "/" + month + "/" + year + "." )
	else :
		logFileHandle = open( logFileName, "a" )

	printNLogInfo( "Starting of script < " + scriptBaseName + " > which PID is < " + pid + " >." )

def initScript() :
	funcName = inspect.stack()[0][3]
	global tmpDir, pid, regExp, pattern
	initArgs()
	pid = str( os.getpid() )
	tmpDir   = getenv( "TMP" )

	if args.log :
		initLog()
		printNLogInfo( "The script < " + scriptBaseName + " > is run on < " + platform.node() + " > the following way:\n" + " ".join(argv) )

	if args.restore :
		regExp = "|".join( args.restore[1:] ).replace(os.sep, '/').replace('.','\.').replace('?', '.').replace('*', '.*').replace('|', '$|')
		if "$" in regExp : regExp = regExp.replace("$","")
		if "|" in regExp : regExp = "(" + regExp + ")"
	else :
		regExp = "|".join( args.fileList    ).replace(os.sep, '/').replace('.','\.').replace('?', '.').replace('*', '.*').replace('|', '$|')
		if regExp : regExp += "$"

	# print "=> regExp = " + regExp
	pattern = re.compile(regExp, re.I)

	if not exists( args.dir ) : makedirs( args.dir )

def isNewer( file1, file2 ) :
	return getmtime( file1 ) < getmtime( file2 )

def isDifferent( file1, file2 ) :
	sig1 = calcChecksum(file1)
	sig2 = calcChecksum(file2)
	return sig1 != sig2

def runCommandAndReturnOutput( myCommand ) :
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def cut( lines, position, separator =" " ) :
	return [ line.split(separator)[position] for line in lines.splitlines() if len(line) != 0 ]

def isRunning( processName ) :
	# print >> stderr, "=> APPEL à la fonction isRunning !"
	if   os.name == "nt"    :
		processName = processName.lower()
		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "tasklist -fi \"imagename eq " + splitext(processName)[0] + ".*\"" )
		pos = 0
	elif os.name == "posix" :
#		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "ps -elf" )
		pos = -1

	found = False
#	processList = cut( stdoutStr.lower(), pos, " " )
	if os.name == "nt" :
		# processName = processName.split(".")[0]
		# processList = [ line.split(".")[0] for line in stdoutStr.lower().splitlines() if len(line) != 0 and "." in line ]
		processList = [ line.split(" ")[0] for line in stdoutStr.lower().splitlines() if len(line) != 0 and "." in line ]

		for process in processList :
			if processName == process :
				found = True;
				break

	# if found : print "=> processList = {" + "\n".join(processList) + "}"

	return found

def pidof( processName ) :
	if   os.name == "nt"    :
		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "tasklist -fi \"imagename eq " + splitext(processName.lower())[0] + ".*\"" )
		pos = 0
	elif os.name == "posix" :
#		stdoutStr, stderrStr, retCode = runCommandAndReturnOutput( "ps -elf" )
		pos = -1

	found = False
#	processList = cut( stdoutStr.lower(), pos, " " )
	if os.name == "nt" :
		processList = [ line.split()[1] for line in stdoutStr.splitlines() if len(line) != 0 and "." in line and "INFO:" not in line ]

	return processList

def killProcess(pid) :
	if   os.name == "nt"    :
		retCode = call( "taskkill -t -f -pid " + pid )
	elif os.name == "posix" :
		retCode = call( "kill -9 " + pid )
	if   retCode == 0 :
		printNLogString( "=> INFO: Successfully killed process of pid : " + pid )
	else :
		printNLogError ( "=> ERROR: The process PID < " + pid + " > could not be killed." )

def restoreFromLogFile( logFile ) :
	if exists( logFile ) :
		yearMonthDay = datetime.today().strftime('%Y%m%d')
		restoreLogFile = dirname( logFile ) + os.sep + "Restore" + "_" + yearMonthDay + ".log"
		with open( restoreLogFile ,"w" ) as restoreLogHandle :
			print "Restoring the original files from their backup ..."
			print >> restoreLogHandle, "Restoring the original files from their backup ..."
			myPattern = re.compile( regExp + ".* copy " )
			with open( logFile ,"r" ) as textfile :
				for line in textfile :
					if myPattern.search( line ) :
						newFile      = line.split( "<" )[1].split( ">" )[0].strip()
						originalFile = line.split( "<" )[2].split( ">" )[0].strip()
						if exists(originalFile) :
							try :
								move(originalFile, newFile)
							except Error as why :
								print >> stderr, "%s." % why
								print >> restoreLogHandle, "%s." % why
							else :
								print originalFile + " -> " + newFile
								print >> restoreLogHandle, originalFile + " -> " + newFile
		print "Done."
		print >> restoreLogHandle, "Done."
	else :
		printNLogErrorAndExit( "The file < " + logFile + " > does not exist.", 1 )

def main() :
	initScript()
	retCode, nbErr = 0,0
	if args.restore :
		restoreFromLogFile( args.restore[0] )
	else :
		zipFile = abspath( args.zipfile ) #Le fichier zip doit etre accessible quel que soit le repertoire ou on est
		if not exists( zipFile ) :
			printNLogError( "The sourcefile < " + zipFile + " > does not exists (anymore?)." )
			retCode = -2
		else :
			chdir( args.dir ) #On travaille en relatif
			zipFileList, zipDirList = zipExtractAll( zipFile, tmpDir )
			for fileName in zipFileList :
				if pattern.search( fileName ) :
					if args.list :
						print fileName
					else :
						baseFileName = basename( fileName )
						if exists( fileName ) :
							if isRunning( baseFileName ) and isNewer( fileName, tmpDir + os.sep + fileName ) :
								if args.kill :
									for pid in pidof( baseFileName ) :
										killProcess( pid )
									if not args.no_backup : backupFile(fileName)
									if args.overwrite or isDifferent( fileName, tmpDir + os.sep + fileName ) :
										printNLogString( "  inflating: " + args.dir + "/" + fileName )
										move( tmpDir+os.sep+fileName, fileName )
								else :
									printNLogError( "The process < " + baseFileName + " > of pid : " + " ".join( pidof( baseFileName) ) + " is/are still running, cannot update it.\n" )
									nbErr += 1
							else :
								if args.overwrite or ( isNewer( fileName, tmpDir + os.sep + fileName ) and isDifferent( fileName, tmpDir + os.sep + fileName ) ) :
									if not args.no_backup : backupFile(fileName)
									if isRunning( baseFileName ) and isNewer( fileName, tmpDir + os.sep + fileName ) :
										if args.kill :
											for pid in pidof( baseFileName ) :
												killProcess( pid )
											printNLogString( "  inflating: " + args.dir + "/" + fileName )
											move( tmpDir+os.sep+fileName, fileName )
										else :
											printNLogError( "The process < " + baseFileName + " > of pid : " + " ".join( pidof( baseFileName) ) + " is/are still running, cannot update it.\n" )
											nbErr += 1
									else :
										printNLogString( "  inflating: " + args.dir + "/" + fileName )
										move( tmpDir+os.sep+fileName, fileName )
						else :
							if args.junk_paths :
								printNLogString( "  inflating: " + args.dir + "/" + baseFileName )
								move( tmpDir+os.sep+fileName, baseFileName )
							else :
								dir = dirname(fileName)
								if dir and not exists(dir) : makedirs(dir)
								printNLogString( "  inflating: " + args.dir + "/" + fileName )
								move( tmpDir+os.sep+fileName, fileName )

			print
			chdir( tmpDir )
			# set_trace()
			for dir in zipDirList :
				if dir :
					if len(listdir(dir)) == 0 : rmdir(dir)
					else : rmtree(dir)

	printNLogString("")
	if args.log :
		print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"

	if nbErr : retCode = 1
	exit( retCode )

main()
