#!/usr/bin/env python
#coding: latin1

import ctypes
import os
from sys import stderr, argv, exit
from math import log
from pdb import set_trace #To add a breakpoint for PDB debugger

def freeSpaceMB(folder):
	if os.name == "nt" :
		free_bytes = ctypes.c_ulonglong(0)
		ctypes.windll.kernel32.GetDiskFreeSpaceExW(ctypes.c_wchar_p(folder), None, None, ctypes.pointer(free_bytes))
		return free_bytes.value/1024.0**2
	elif os.name == "posix" :
		st = os.statvfs(folder)
		return st.f_bavail * st.f_frsize/1024.0**2

def humanReadable(size) :
	if size <= 0 : size = "%7d" % 0
	else :
		units = [ "", "K", "M", "G", "T", "P", "E", "Z", "Y" ]
		devider = int( log(size,1024) )
		size = size * 1.0 / 1024**devider

		if devider == 0 :
			size = "%5d" % size
		else :
			size = "%4.2f" % size

		size += units[ devider ]

	return size

def freeSpace(folder) :
	if os.name == "nt" :
		free_bytes = ctypes.c_ulonglong(0)
		ctypes.windll.kernel32.GetDiskFreeSpaceExW(ctypes.c_wchar_p(folder), None, None, ctypes.pointer(free_bytes))
		return free_bytes.value
	elif os.name == "posix" :
		st = os.statvfs(folder)
		return st.f_bavail * st.f_frsize

def main() :
	minimumSpaceRequired = 100.0*1024*1024 #100MiB minimum par defaut
	if len(argv) > 1 : minimumSpaceRequired = float(argv[1])*1024*1024

	myFreeSpace = freeSpace(".")
	if myFreeSpace > minimumSpaceRequired :
		print "=> INFO: You have " + humanReadable(myFreeSpace) + " left, it's enough."
	else :
		print >> stderr, "=> ERROR: Not enough free space: "+ humanReadable(minimumSpaceRequired) + " is needed but you have only " + humanReadable(myFreeSpace) + " left." 
		exit(1)

main()
