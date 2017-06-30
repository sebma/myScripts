#!/usr/bin/env python
#coding: latin1
import os
from os import listdir, getcwd, makedirs
from os.path import getmtime, exists, splitext
from time import strftime, localtime
from shutil import move
from sys import stderr
from timeit import timeit

import time

def timing(f):
    def wrap(*args):
        time1 = time.time()
        ret = f(*args)
        time2 = time.time()
        print '%s function took %0.3f ms' % (f.func_name, (time2-time1)*1000.0)
        return ret

    return wrap


@timing

def connectSSH(context):
    pass

def main() :
	regExp = "^toto"
	prefix = "toto"
	suffix = ".Log"

	fileBaseName = "toto_35814.log"
	fileBaseName.lower().endswith( suffix )
	#re.search( regExp, fileBaseName )
