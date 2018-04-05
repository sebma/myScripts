#!/usr/bin/env python
#coding: latin1

import os
from os.path import exists
import sys
from sys import argv, stderr, exit
from platform import python_version, python_version_tuple, node
from pdb import set_trace #To add a breakpoint for PDB debugger

def checkPythonVersion( minimalVersion=2.6 ) :
	currentVersion = float( python_version_tuple()[0] + '.' + ''.join( python_version_tuple()[1:] ) )
	if currentVersion < minimalVersion :
		print >> stderr,  "=> ERROR: The minimum version needed for Python is <" + str(minimalVersion) + "> but you have the version <" + str(currentVersion) + ">" + " installed in < " + sys.prefix + " > on server <" + node() + ">.\n"
		return 1
	else :
		return 0

def which(file) :
	for path in os.environ["PATH"].split( os.pathsep ):
		if exists(path + os.sep + file):
				return path + os.sep + file

	return None

def main() :
	if len(argv) > 1 :
		retCode = checkPythonVersion( float( argv[1] ) )
	else :
		retCode = checkPythonVersion( minimalVersion=2.6 )

	if( retCode == 0 ) :
		print "=> Python version: <" + python_version() + ">" + " installed in < " + sys.prefix + " > on server <" + node() + ">.\n"
		print "=> Checking if < python.exe > is in the PATH variable and show where it is ..."
		pythonPath = which( "python.exe" )
		if( pythonPath ) :
			print pythonPath
		else :
			print >> stderr, "=> python.exe is not in the PATH."
#			print "=> Adding " + sys.prefix + " to the PATH variable ...\n"
			PATH = '"' + os.environ["PATH"] + os.pathsep + sys.prefix + '"'
#			retCode = subprocess.call( "setx PATH " + PATH + " -m", shell=True )

	#raw_input("Press Enter to continue...")
	return retCode

main()
