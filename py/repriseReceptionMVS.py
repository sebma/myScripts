#!/usr/bin/env python
#coding: latin1

import os
from os import chdir, listdir, getcwd, getenv, makedirs
from os.path import basename, dirname, splitext, exists, abspath
import sys
from sys import stderr, exit
import re
from datetime import datetime
from platform import node, python_version_tuple
from subprocess import Popen, PIPE, call, STDOUT
import inspect
from argparse import ArgumentParser
from glob import glob #Filename Globbing patterns
import platform
from pdb import set_trace #To add a breakpoint for PDB debugger

def checkPythonVersion( minimalVersion=2.6 ) :
	currentVersion = float( python_version_tuple()[0] + '.' + ''.join( python_version_tuple()[1:] ) )
	if currentVersion < minimalVersion :
		print >> stderr,  "=> ERROR: The minimum version needed for Python is <" + str(minimalVersion) + "> but you have the version <" + str(currentVersion) + ">" + " installed in < " + sys.prefix + " > on server <" + node() + ">.\n"
		return 1
	else :
		return 0

def isUnixScript(fileName) :
	if fileNewlineChar(fileName) != "\n" :
		print >> stderr, "=> ERROR: You must convert the script < " + fileName + " > to UNIX format so it can be run on both Windows and UNIX/Linux."
		exit(1)

def fileNewlineChar(fileName) :
	with open( fileName, "U" ) as fileHandle :
		fileHandle.readline()
		fileHandle.readline()
		newlineChar = fileHandle.newlines

	return newlineChar

def printNLogString(string) :
	print string
	with open( logFileName, "a") as logFileHandle :
		print >> logFileHandle, string

def printNLogInfo(message) :
	if message :
		callerFunctionName = inspect.stack()[1][3]
		if callerFunctionName == "<module>" : callerFunctionName = "main"

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]
		message = timestamp + " - [" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	with open( logFileName, "a") as logFileHandle :
		print >> logFileHandle, message

def runCommandAndReturnOutput(command) :
	printNLogInfo( "RUNNING command: \n\n" + command + "\n" )
	myProcess = Popen( command, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()
	printNLogInfo( "END of command with return code: <" + str(myProcess.returncode) + ">.\n" )

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def findParameterInFile( fileName, parameter, separator, pos ) :
	textFileHandle = open( fileName, "rt" )

	result = ""
	line = " "
	while line != "" :
		line = textFileHandle.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == "\n" : continue

		line = line.strip()
		if line != "" and line[0:3].lower() != "rem" and line[0] != "#" :
			if parameter in line :
				line = re.sub( separator + '+' , separator, line) #Replace multiple occurences of separators by separator
				if pos == "last" : result = line.split( separator )[-1]
				else : result = line.split( separator )[ int(pos) ]
				textFileHandle.close()

				return result

	textFileHandle.close()
	return result

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='*', help = "filename globbing partern list to process, default is *.", default = "*" )
	parser.add_argument( "-d", "--dir", help="check files in dir.", default = dirname( __file__ ) )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

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

	logBaseDir = nextDataMountPoint + os.sep + "LOGS" + os.sep + "Reception"
	logDir = logBaseDir + os.sep + year + os.sep + yearMonth + os.sep + yearMonthDay

	if not exists( logDir ) : makedirs( logDir )
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"

	if not exists(logFileName) :
		printNLogString( "="*80 + "\n" + yearMonthDay + " - Initiating the log of the script <" + scriptBaseName + "> for the " + theDate + ".\n" + "="*80 + "\n" )

	logFileName = abspath(logFileName) #Convertit le chemin en absolu pour eviter d'avoir des ennuis apres un chdir

def initScript() :
	isUnixScript(__file__)
	initArgs()
	initDates()
	global localSPN, recvMVSDir, receivedFromMVSPattern, tomDir, spn, sfn

	global currentDataMountPoint, nextDataMountPoint
	if os.name == "nt" : currentDataMountPoint = "D:"; nextDataMountPoint = "J:"
	elif os.name == "posix" : currentDataMountPoint = "/d"; nextDataMountPoint = "/j"

	initLog()

	defvareurScript = getenv("DEFVAREUR")
	if not defvareurScript : 
		printNLogErrorAndExit( "The environment variable <DEFVAREUR> is not defined.", 1 )

	tomDir = findParameterInFile( defvareurScript, "TOM_DIR", "=", "last" )

	localSPN = node()
	recvMVSDir = dirname( __file__ )
	receivedFromMVSPattern = "TRANSTOM." + localSPN + "."
	env = node()[0]

	if env == "D" :
		spn = "MELD"
		sfn = "DMILVT"
	elif env == "H" :
		spn = "MELH"
		sfn = "HMILVT"
	elif env == "P" :
		spn = "MELN"
		sfn = "PMILVT"

def isAdmin() :
	if   os.name == "nt" :
		retCode = call( "net session", stdout=open(os.devnull), stderr=STDOUT )
	elif os.name == "posix" :
		print >> stderr, "TO BE DONE !"

	if not retCode :return True
	else :			return False

def pidof(regExp) :
	selfPID = str( os.getpid() )
	myPattern = re.compile(regExp, re.I)

	PIDs = []
	if   os.name == "posix" :
		if platform.system() == "Linux" :
			proc = Popen('pgrep ' + " ".join( args.patternList ) , stdout=PIPE)
			for line in proc.stdout :
				print "line = " + line
		else :
			interpreter = "ksh"
			if checkPythonVersion(2.7) :
				from subprocess import check_output
				outPut = check_output( "ps -elf | grep " + regExp, shell=True )
				for line in outPut :
					print "line = " + line
			else :
				proc1 = Popen('ps -elf', stdout=PIPE)
				proc =  Popen('grep ' + regExp, stdin=proc1.stdout, stdout=PIPE)
				for line in proc.stdout :
					print "line = " + line
			print >> stderr, "TO BE DONE !"
	elif platform.system() == "Windows" :
		interpreter = "cmd"
		regExp2 = "Prompt \- "
		tasklistPrompt = re.compile(regExp2)
		separator = ","

		if isAdmin() :
			wmicProcessProc = Popen("wmic process get caption,commandline,processid -format:csv", stdout=PIPE)
			for line in wmicProcessProc.stdout:
				line = line.strip()
				wmicLineColumns = line.split(separator)
				if not line or wmicLineColumns[0] == "Node" : continue
				if myPattern.search( line ) :
					pid = wmicLineColumns[-1]
					if pid != selfPID :
						PIDs.append( pid )
		else :
			tasklistProc = Popen('tasklist -fo:csv', stdout=PIPE)
			for line in tasklistProc.stdout :
				line = line.strip()
				tlistLineColumns = line.split(separator)
				if not line or tlistLineColumns[0] == '"Image Name"' : continue
				if myPattern.search( line ) and not tasklistPrompt.search( line ) :
					pid = tlistLineColumns[1].split('"')[1]
					if pid != selfPID :
						PIDs.append( pid )

	return PIDs

def main() :
	initScript()
	printNLogInfo( "STARTING script: < " + __file__ + " >." )

	nb, code = 0, 0

	chdir( args.dir )
	# set_trace()
	for currentGlobbingPattern in args.fileList :
		fileList = glob( receivedFromMVSPattern + currentGlobbingPattern )
		printNLogInfo( "Found " + str( len(fileList) ) + " files matching pattern < " + receivedFromMVSPattern + currentGlobbingPattern + " > to process." )
		for fileBaseName in fileList :
			fileName = recvMVSDir + os.sep + fileBaseName
			# if fileBaseName.startswith( receivedFromMVSPattern ) and len( pidof("reception_mvs.py" + ".*" + fileBaseName) ) == 0 :
			if len( pidof("reception_mvs.py" + ".*" + fileBaseName) ) == 0 :
				command = tomDir  + os.sep + "exit" + os.sep + "reception_mvs.py RESTART " + sfn +  " R " + spn + " " + fileName + " 0000 0000 " + fileBaseName
				stdout, myStderr, retCode = runCommandAndReturnOutput( command )
				if myStderr : printNLogString( myStderr )
				if retCode == 0 : nb+=1

	printNLogInfo( str(nb) + " files were processed." )

	printNLogInfo( "END of script: < " + __file__ + " >.\n" )

	print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"

main()
