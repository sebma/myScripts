#!/usr/bin/env python
#coding: latin1

import os,re
from sys import stderr, exit
from platform import node
import subprocess

def isAdmin() :
	if   os.name == "nt" :
		# retCode = subprocess.call( "net session >nul 2>&1", shell = True )
		retCode = subprocess.call( "net session", stdout=open(os.devnull), stderr=subprocess.STDOUT )
	elif os.name == "posix" :
		print >> stderr, "TO BE DONE !"

	if not retCode :return True
	else :			return False

def main() :
	retCode = 0
	if isAdmin() :
		print "=> You are admin of the server/workstation < " + node() + " > :)."
	else :
		print >> stderr, "=> You are NOT admin of the server/workstation < " + node() + " > :(."
		retCode = 1
	exit( retCode )

main()
