#!/usr/bin/env python
#coding: latin1

import os
from os import getenv
from socket import gethostname, gethostbyname, gethostbyaddr
from sys import stderr, exit
from subprocess import Popen, PIPE
from pdb import set_trace #To add a breakpoint for PDB debugger

def runCommandAndReturnOutput(myCommand) :
	myProcess = Popen( myCommand, shell=True, stdout=PIPE, stderr=PIPE, universal_newlines=True )
	myOutput = myProcess.communicate()

	myList = list( myOutput )
	myList.append( myProcess.returncode )

	return myList

def nslookup( ip ) :
	if   os.name == "nt" :
		myCommand = "nslookup " + ip
		resultLineNumber = 3
	elif os.name == "posix" :
		myCommand = "host " + ip
		resultLineNumber = 0

	myStdout, myStderr, retCode = runCommandAndReturnOutput( myCommand )
	if myStderr or retCode :
		print >> stderr, myStderr
		exit(retCode)
	else :
		myStdout = myStdout.splitlines()
		DNSName = myStdout[resultLineNumber].split()[-1].split(".")[0].upper()

	return DNSName

def main() :
	try :
		ip = gethostbyname( gethostname() )
		DNSName = nslookup( ip )
		print DNSName

	except gaierror as why :
		print >> stderr, "=> Could not request the DNS servers: " % why

#	raw_input("Press Enter to continue...")

main()
