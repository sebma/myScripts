#!/usr/bin/env python
#coding: latin1

from sys import argv, stderr, exit
import os
from os.path import basename, exists
import re
from time import sleep
from signal import signal, SIGINT, pause
from socket import socket, gethostname, AF_INET, SOCK_STREAM, error
#import socket

def stopProg( signum, frame ) :
	for currentSocket in socketList :
		port = currentSocket.getsockname()[1]
		print "=> Fermeture du port : <" + str(port) + ">."
		currentSocket.close()
		currentSocket = None

def main() :
	retCode = 0
	backlog = 5
	scriptBaseName = basename(__file__)
	argc = len(argv)
	if argc == 1 :
		print >> stderr, "=> Usage: <" + scriptBaseName + "> <SI.properties>"
		exit(1)

	propertiesFilename = argv[1];
	if not exists( propertiesFilename ) :
		print >> stderr, "=> ERROR: <" + propertiesFilename + "> does not exists."
		exit(2)

	textFileHandle = open(propertiesFilename, "rb")
	line = " "
	tcpPortList = []
	pattern = "\.PORT=\s*(\d+)"
	while line != "" :
		line = textFileHandle.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == os.linesep : continue

		line = line.strip()
		result = re.search( pattern, line )
		if result :
			tcpPortList.append( int(result.group(1)) )

	textFileHandle.close()

#	hostname = socket.gethostname()
	hostname = gethostname()
	global socketList
	socketList = []
	for tcpPort in tcpPortList :
		print "=> Creating new socket on server <" + hostname + "> ..."
		mySocket = socket(AF_INET, SOCK_STREAM)
#		mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		try:
			print "=> Binding socket on port <" + str(tcpPort) + "/tcp> ..."
			mySocket.bind( (hostname, tcpPort) )
			socketList.append( mySocket )
#		except socket.error, msg:
		except error, msg:
			message = str(msg) + " on port <" + str(tcpPort) + "/tcp>."
			print >> stderr, message
			mySocket.close()
			mySocket = None
		print

	signal(SIGINT, stopProg)

	pause() #wait for signal

	return(retCode)

main()

