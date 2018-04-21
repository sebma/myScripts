#!/usr/bin/env python

import plistlib
import urllib2
import sys
from pdb import set_trace
import xml
import xml.dom
from bs4 import BeautifulSoup
import requests
import lxml
import lxml.html
import lxml.html.soupparser
#from lxml import html
#set_trace()


#ITUNES_VER = '7.4.1'
ITUNES_VER = '9'

USER_AGENT = 'iTunes/' + ITUNES_VER

def downloadHTML(url):
	page = requests.get( url, headers = {'user-agent': USER_AGENT } )
	return page.content

def get_props(url):
    htmlResponse = downloadHTML(url)
    try : tmp = plistlib.readPlistFromString( htmlResponse )
    except xml.parsers.expat.ExpatError, ex:
        print ex
        tmp = ""
    return tmp

def get_feedLXML(url):
	feedURL = ''
	htmlSource = downloadHTML(url)
#	root = lxml.html.soupparser.fromstring(htmlSource)
	tree = lxml.html.fromstring(htmlSource)
	set_trace()
	feedURL = tree.xpath('//button[@kind="episode"]/@feed-url/text()')

def get_feedBeautifulSoup(url):
	feedURL = ''
	htmlSource = downloadHTML(url)
	soup = BeautifulSoup(htmlSource) #Tres lent
	for button in soup.find_all('button'):
		feedURL = button.get('feed-url')
		if feedURL : break

	return feedURL

def get_feed(url):
	props = get_props(url)
#	with open("file.txt","w") as file : print >> file, str(props)

	return props['items'][0]['feed-url']

def get_id(url):
	id = url.split('/')[-1][2:]
	return id

if __name__ == '__main__':
    for url in sys.argv[1:]:
		id = get_id(url)
		print get_feedBeautifulSoup('http://itunes.apple.com/podcast/id'+id)
#		print get_feedLXML('http://itunes.apple.com/podcast/id'+id)
#		print get_feed('http://itunes.apple.com/podcast/id'+id)
