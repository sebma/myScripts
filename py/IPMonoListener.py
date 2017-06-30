#!/usr/bin/env python
#coding: latin1

import os
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

# def signal_handler(signal, frame):
	# print >> stderr, 'You pressed Ctrl+C!'

	# endScript(1)

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "-u","--udp", default = False, action='store_true', help="use udp protocol." )
	parser.add_argument( "-t","--tcp", default = True, action='store_true', help="use tcp protocol." )
	parser.add_argument( "-p", "--port", type = int, help="listen on <port> port.", required=True )

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
	# signal(SIGINT, signal_handler)

	serverIP = str( gethostbyname( gethostname() ) )
	global mySocket
	if args.tcp :
		protocol = "tcp"
		mySocket = socket(AF_INET, SOCK_STREAM)
	else :
		protocol = "udp"
		mySocket = socket(AF_INET, SOCK_DGRAM)

	mySocket.bind( ("", args.port) )
	mySocket.listen(5)
	print "=> Listening on port {p}...".format(p=args.port)
	clientSocket, clientIP = mySocket.accept()
	while True:
		try :
			print
		except KeyboardInterrupt as why :
			print >> stderr, os.linesep + "=> CTRL+C : %s." % why
			mySocket.close()
			mySocket = None
			exit(0)
		except error as why :
			print >> stderr, os.linesep + "=> ERROR: %s." % why
			mySocket.close()
			mySocket = None
			exit(1)
		else :
			print >> stderr, "=> The computer of IP address " + str(clientIP) + " has just connected."
			clientRequest, clientIP = clientSocket.recv(255)
			if not clientRequest : break
			else : 
				stdout.write( "".join(clientRequest) )
				# print "%d%d" % ( ord(clientRequest[0]) , ord(clientRequest[0]) ),
				print clientRequest.encode("hex"),
			# if clientRequest[0] == 'q' : break

			if clientRequest[0] == 'q' :
				clientSocket.send("=> The IP route <" + str(clientIP[0]) + "> => <" + str(serverIP) + "> on <" + str(args.port) +"/" + protocol + "> is opened.\n")
				clientSocket.close()
				clientSocket = None
				break

	mySocket.close()
	mySocket = None
	exit(0)

main()
