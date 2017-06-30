#!/usr/bin/env python
#coding: latin1

import os
from os import chdir, listdir, getcwd, getenv
import sys
from sys import stderr, exit
import re
import datetime #Pour: today, now
from platform import node
from os.path import basename, dirname, splitext
from subprocess import Popen, PIPE
import inspect

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

def printNLogInfo(message) :
	logFileHandle = open( logFileName, "a")
	if message :
		callerFunctionName = inspect.stack()[1][3]
		if callerFunctionName == "<module>" : callerFunctionName = "main"

	#	timestamp = datetime.datetime.now().strftime('%H:%M:%S') + str(datetime.datetime.now().microsecond)
		timestamp = str(datetime.datetime.now())[11:23]
		message = timestamp + " - [" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	print >> logFileHandle, message
	logFileHandle.close()

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

def initScript() :
	isUnixScript(__file__)
	global scriptBaseName, logFileName, localSPN, recvMVSDir, receivedFromMVSPattern, tomDir, tomExecDir, spn, sfn

	defvareurScript = getenv("DEFVAREUR")
	if not defvareurScript : 
		printNLogErrorAndExit( "The environment variable <DEFVAREUR> is not defined.", 1 )

	tomExecDir = findParameterInFile( defvareurScript, "TOM_EXE", "=", "last" )

	yearMonthDay = datetime.date.today().strftime('%Y%m%d')
	scriptBaseName = basename( __file__ )
	logFileName = dirname( __file__ ) + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"
	localSPN = node()
	recvMVSDir = dirname( __file__ )
	receivedFromMVSPattern= "TRANSTOM." + localSPN + "."
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

def main() :
	initScript()
	printNLogInfo( "STARTING script: < " + __file__ + " >." )

	nb, code = 0, 0
	for fileBaseName in listdir( recvMVSDir ):
		fileName = recvMVSDir + os.sep + fileBaseName
		if fileBaseName.startswith( receivedFromMVSPattern ):
			command = tomExecDir  + os.sep + "exit" + os.sep + "reception_mvs.py RESTART " + sfn +  " R " + spn + " " + fileName + " 0000 0000 " + fileBaseName
			stdout, myStderr, retCode = runCommandAndReturnOutput( command )
			if myStderr : printNLogString( myStderr )
			if retCode == 0 : nb+=1

	printNLogInfo( str(nb) + " files were processed." )

	printNLogInfo( "END of script: < " + __file__ + " >.\n" )

	print >> stderr, "=> La log du script <" + scriptBaseName + "> est: < " + logFileName + " >.\n"

main()
