#!/usr/bin/env python
#coding: latin1

import urllib
import urllib2
from os.path import basename
from urlparse import urlsplit
import argparse
import sys
from sys import argv, stderr, exit

def report(blocknr, blocksize=8192, size):
	current = blocknr*blocksize
	sys.stdout.write("\r{0:.2f}%".format(100.0*current/size))

def downloadFile(url):
	print "\n",url
	fname = url.split('/')[-1]
	print fname
	urllib.urlretrieve(url, fname, report)

def url2name(url):
	return basename(urlsplit(url)[2])

def download(url, localFileName = None):
	localName = url2name(url)
	req = urllib2.Request(url)
	r = urllib2.urlopen(req)
	CHUNK_SIZE = 8192
	if r.info().has_key('Content-Disposition'):
		# If the response has Content-Disposition, we take file name from it
		localName = r.info()['Content-Disposition'].split('filename=')[1]
		if localName[0] == '"' or localName[0] == "'":
			localName = localName[1:-1]
	elif r.url != url: 
		# if we were redirected, the real file name we take from the final URL
		localName = url2name(r.url)
	if localFileName: 
		# we can force to save the file as specified name
		localName = localFileName

	f = open(localName, 'wb')
	f.write(r.read(CHUNK_SIZE))
	f.close()

def initArgs() :
	parser = argparse.ArgumentParser()
	parser.add_argument("url", help="URL of the remote file to download.")

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

def main() :
	initArgs()
	#downloadFile( args.url )
	download( args.url )

main()
