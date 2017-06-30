#!/usr/bin/env python
#coding: latin1

import os #Pour: basename
import sys #Pour: argv
import hashlib # Pour: md5, sha1, sha256, ...
from datetime import datetime

def md5sum(filename):
	testFile = open(filename, "rb")
	m = hashlib.md5()

	while True:
		data = testFile.read(4*1024*1024)
		if not data: break
		m.update(data)
	hash = m.hexdigest()
	return hash

def sha1sum(filename) :
	testFile = open(filename, "rb")
	m = hashlib.sha1()

	while True:
		data = testFile.read(4*1024*1024)
		if not data: break
		m.update(data)
	hash = m.hexdigest()
	return hash

def sha256sum(filename) :
	testFile = open(filename, "rb")
	m = hashlib.sha256()

	while True:
		data = testFile.read(4*1024*1024)
		if not data: break
		m.update(data)
	hash = m.hexdigest()
	return hash

def main() :
	startTime = datetime.now()

	argc = len(sys.argv)
	if argc == 1 :
		print >> sys.stderr, "=> Usage:", os.path.basename(__file__) + " <fichier>"
		sys.exit(1)

	file = sys.argv[1]
	print "md5(", file, ") =", md5sum(file)
	print "sha1(", file, ") =", sha1sum(file)
	print "sha256(", file, ") =", sha256sum(file)

	print "=> The script", os.path.basename(__file__) + " took " + str(datetime.now()-startTime)

main()
