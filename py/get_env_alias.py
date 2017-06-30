#!/usr/bin/env python
#coding: latin1

from platform import node
from sys import exit, stderr
from os import getenv
from os.path import basename
from re import search

hostname = node().lower()
username = getenv("USER")
print "hostname " + hostname
print "USER " + username
scriptBaseName = basename(__file__)

found = search( "eur.*adm", username )
if found :
	print
else :
	print >> stderr, "=> The program <" + scriptBaseName + "> cannot be run as <" + username + ">."
#	exit(1)

found = search( "(eur.*)adm", username )
if found :
	env = found.group(1)
	print "env = " + env
