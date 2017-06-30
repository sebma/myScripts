#!/usr/bin/env python
#coding: latin1

from sys import stderr, exit
from platform import python_version,python_version_tuple

def isUnix(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.read() :
		print >> stderr, "=> ERROR: You must convert the script <" + fileName + "> to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def checkPythonVersion() :
	pythonVersionTuple = python_version_tuple()
	pythonMinimalVersionTuple = ['2','6','5']
	pythonMinimalVersion = '.'.join(pythonMinimalVersionTuple)
	if pythonVersionTuple < pythonMinimalVersionTuple :
		print >> stderr,  "=> ERROR: The minimum version needed for Python is <" + pythonMinimalVersion + "> but you have the version <" + python_version() + ">."
		exit(1)
	else : print "=> Using Python version: <" + python_version() + ">"

isUnix(__file__)
checkPythonVersion()
