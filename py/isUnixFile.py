#!/usr/bin/env python
#coding: latin1

from sys import stderr, exit, argv

def isUnixScript(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.readline() :
		print >> stderr, "=> ERROR: You must convert the script <" + fileName + "> to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def isUnix(fileName) :
	with open(fileName,"rb") as fileHandle :
		firstLine = fileHandle.readline()
	return "\r\n" not in firstLine

def main() :
	print str(isUnix(argv[1]))

main()
