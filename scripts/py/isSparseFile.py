#!/usr/bin/env python

import os
from sys import stderr, exit, argv
fileName = argv[1]
fileStats = os.stat( fileName )
if fileStats.st_blocks*512-fileStats.st_size < 0 :
	print >> stderr, "=> INFO: <"+fileName+"> is a sparse file !"
	exit(1)
else :
	print >> stderr, "=> INFO: <"+fileName+"> is NOT a sparse file !"
	exit(0)
