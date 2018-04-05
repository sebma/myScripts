#!/usr/bin/env python
#coding: latin1

import os,sys
from sys import stdout
from time import sleep

def printf(format, *args) : 
	if sys.version_info[0] > 2 :
		#print( format % args, end="" )
		pass
	else :
		print format % args,
		if os.name == "posix" : stdout.flush()

printf("=>   0%%")
for i in range(0,101,10) :
	if i >= 100 : printf('\b' * 5 + "%2d%%" , i)
	else : printf('\b' * 4 + "%2d%%" , i)
	sleep(1)
print

