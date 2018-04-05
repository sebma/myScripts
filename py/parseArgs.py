#!/usr/bin/env python
#coding: latin1

from sys import argv, stderr, exit

def isUnix(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.read() :
		print >> stderr, "=> ERROR: You must convert the script <" + fileName + "> to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def main() :
	isUnix(__file__)
	print "OK."
	argc = len(argv)
	arg1, arg2, arg3, arg4 = argv[1:argc]
	print "arg2 = " + arg2
	print "argv[1:" + str(argc) + "] = " + str(argv[1:argc])

main()
