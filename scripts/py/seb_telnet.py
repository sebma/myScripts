#! /usr/bin/env python

from os.path import basename, exists
import telnetlib
import sys
from socket import *

argc = len(sys.argv)
	if( argc == 1 ) :
		print >> stderr, "=> Usage: " + basename(__file__) + " <remote server> [<port>]"
		exit(-1)

	host = sys.argv[1]
	if len(sys.argv) > 2:
		servicename = sys.argv[2]
	else:
		servicename = 'telnet'

	if '0' <= servicename[:1] <= '9':
		port = eval(servicename)
	else:
		try:
			port = getservbyname(servicename, 'tcp')
		except error:
			sys.stderr.write(servicename + ': bad tcp service name\n')
			sys.exit(2)



