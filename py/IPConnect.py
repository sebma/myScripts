#!/usr/bin/env python
#coding: latin1

import os
from os import read
from sys import stdout, stderr, exit
from argparse import ArgumentParser
import inspect
# from socket import socket, gethostname, gethostbyname, AF_INET, SOCK_STREAM, error
from socket import socket, AF_INET, SOCK_STREAM, SOCK_DGRAM, error, gethostbyname, gethostname
from signal import signal, SIGINT
from pdb import set_trace #To add a breakpoint for PDB debugger

def printf(format, *args) : 
	print format % args,
	if os.name == "posix" : stdout.flush()

def signal_handler(signal, frame):
	print >> stderr, 'You pressed Ctrl+C!'

	endScript(1)

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "-u","--udp", default = False, action='store_true', help="use udp protocol." )
	parser.add_argument( "-t","--tcp", default = True, action='store_true', help="use tcp protocol." )
	parser.add_argument( "-p", "--port", type = int, help="listen on <port> port.", required=True )
	parser.add_argument("IP", help="IPAdress to connect to.")

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

	if args.udp :   args.tcp = False
	elif args.tcp : args.udp = False

def initScript() :
	funcName = inspect.stack()[0][3]
	initArgs()

def endScript(retCode) :
	mySocket.close()
	mySocket = None

	exit(1)

def main() :
	initScript()
	# hostname = node().lower()

	remoteIP = str( args.IP )
	global mySocket
	if args.tcp :
		protocol = "tcp"
		mySocket = socket(AF_INET, SOCK_STREAM)
	else :
		protocol = "udp"
		mySocket = socket(AF_INET, SOCK_DGRAM)

	try :
		mySocket.connect( (args.IP, args.port) )
		mySocket.listen(1)
		clientSocket, clientIP = mySocket.accept()
	except error as why :
		print >> stderr, os.linesep + "=> ERROR: %s." % why
		mySocket.close()
		mySocket = None
		exit(1)
	else :
		while True:
			data = read(0, 4*1024)
			if not data: break

		mySocket.send(data)

		mySocket.close()
		mySocket = None
		exit(0)

main()
