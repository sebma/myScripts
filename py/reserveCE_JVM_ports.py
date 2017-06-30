#!/usr/bin/env python
#coding: latin1

import os
from re import search
from sys import argv, stderr, exit
from platform import node
from os.path import basename, dirname, splitext, exists
import datetime
from socket import socket, gethostname, gethostbyname, AF_INET, SOCK_STREAM, error
from signal import signal, pause, SIGUSR1, SIGINT

def initMain() :
	global scriptDir
	scriptDir = dirname(__file__)

	global signalType1, signalType2
	signalType1 = SIGUSR1
	signalType2 = SIGINT

	global hostname, username
	hostname = node().lower()
	username = os.getenv("USER")

	global scriptBaseName,logFileName, logDir, beginDate
	scriptBaseName = basename(__file__)
	beginDate = datetime.datetime.now()
	logFileName = splitext( scriptBaseName )[0] + "_" + beginDate.strftime('%Y%m%d') + ".log"
	logDir = scriptDir + os.sep + ".." + os.sep + "log"
	if not exists(logDir) : os.makedirs(logDir)

def printNLogMessage(message) :
	logFileHandle = open( logDir + os.sep + logFileName, "a" )
	message = "=> INFO: " + message
	print message
	print >> logFileHandle, message

def printNLogError(error) :
	logFileHandle = open( logDir + os.sep + logFileName, "a" )
	error = "=> ERROR: " + error + os.linesep
	print >> stderr, error
	print >> logFileHandle, error

def stopProg( signum, frame ) :
	printNLogMessage( "==> Signal number <" + str(signum) + "> received." + os.linesep )
	for currentSocket in socketList :
		port = currentSocket.getsockname()[1]
		printNLogMessage( "=> Fermeture du port : <" + str(port) + ">." )
		currentSocket.close()
		currentSocket = None

def main() :
	initMain()
	printNLogMessage( beginDate.strftime("%d/%m/%y %H:%M:%S") )

	retCode = 0
	backlog = 5
	scriptBaseName = basename(__file__)
	argc = len(argv)
	if argc == 1 :
		printNLogError( "=> Usage: <" + scriptBaseName + "> <SI.properties>" )
		exit(1)

	found = search( "(eur.*)adm", username )
	if found :
		nameAlias = hostname[0] + found.group(1)
		print "ipAlias = " + nameAlias
	else :
		print >> stderr, "=> The program <" + scriptBaseName + "> cannot be run as <" + username + ">."
		exit(2)

	propertiesFilename = argv[1];
	if not exists( propertiesFilename ) :
		printNLogError( "The file <" + propertiesFilename + "> does not exists." )
		exit(3)

	textFileHandle = open(propertiesFilename, "rb")
	line = " "
	tcpPortList = []
	pattern = "\.PORT=\s*(\d+)"
	while line != "" :
		line = textFileHandle.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == os.linesep : continue #On saut les lignes vides

		line = line.strip() #On supprime les blancs inutiles
		found = search( pattern, line ) #On recherche la pattern definie plus haut
		if found :
			tcpPortList.append( int(found.group(1)) ) #On recupere la premiere sous chaine definie entre parenthese dans la pattern

	textFileHandle.close()

	if hostname = 'soltech': nameAlias = hostname

	ipAlias = gethostbyname( nameAlias )
	global socketList
	socketList = []
	for tcpPort in tcpPortList :
		printNLogMessage( "=> Creating new socket on server <" + ipAlias + "> ..." )
		mySocket = socket(AF_INET, SOCK_STREAM)
#		mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		try:
			printNLogMessage( "=> Binding tcp socket on port <" + str(tcpPort) + "> ..." )
			mySocket.bind( (ipAlias, tcpPort) )
			socketList.append( mySocket )
#		except socket.error, msg:
		except error, msg:
			message = str(msg) + " on tcp port <" + str(tcpPort) + ">."
			printNLogError( message )
			mySocket.close()
			mySocket = None
		print

	signal( signalType1, stopProg ) #Define signal trap for signalType1
	signal( signalType2, stopProg ) #Define signal trap for signalType2

	pause() #wait for signal

	printNLogMessage( datetime.datetime.now().strftime("%d/%m/%y %H:%M:%S") )
	print >> stderr, "=> logFileName = <" + logDir + os.sep + logFileName + ">."

	return(retCode)

main()
