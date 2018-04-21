#!/usr/bin/env python
#coding: latin1

from sys import argv, stderr, exit
import os
from os.path import basename, exists
import re
from time import sleep
from signal import signal, SIGINT

def stopProg( signum, frame) :
#	for socket in socketList :
#		socket.close()
#	exit(0)

	for port in tcpPortList :
		print "=> Fermeture du port : <" + port + ">."

	exit(0)

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

	testFileHandle = open(propertiesFilename, "rb")
	line = " "
	global tcpPortList
	tcpPortList = []
	pattern = "\.PORT=\s+(\d+)"
	while line != "" :
		line = testFileHandle.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == os.linesep : continue

		line = line.strip()
		result = re.search( pattern, line )
		if result :
			tcpPortList.append( result.group(1) )

	global socketList
	socketList = []
	for tcpPort in tcpPortList :
		print "=> tcpPort = <" + tcpPort + ">"
#		mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#		socketList.append( mySocket )
#		mySocket.bind(( socket.gethostname(), tcpPort ))
#		mySocket.listen(backlog)
#		print

	#signal(SIGINT, stopProg)
	signal(SIGINT, stopProg)

	while True:
		pass

	return(retCode)

main()

