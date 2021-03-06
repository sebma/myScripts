#!/usr/bin/env python

#From : https://github.com/jfhbrook/methlabs/blob/master/bin/methlabs

from pdb import set_trace #To help debugging
import re
import sys
from os import system, path, remove
from sys import stderr, exit

filename=path.basename(sys.argv[1])
#set_trace()

if len( filename.split('.') ) > 2 :
	print >> stderr, "=> ERROR: With matlab -r, you cannot launch a script that contains more than one dot." 
	exit(1)

with open(filename, 'r') as infile:
    with open('methlabs_tmp_' + filename, 'w') as outfile:
        for pos, line in enumerate(infile):
#            if pos>0 and line!="\n":
            if pos>0 or not line.strip().startswith( '#!') :
                outfile.write(line)

#system("matlab -nosplash -nodesktop -r 'methlabs_tmp_"+re.split(r'\.', filename)[0]+"; exit'")
retCode = system("matlab -nojvm -r 'methlabs_tmp_"+re.split(r'\.', filename)[0]+" "+" ".join(sys.argv[2:])+"; exit' | tail +11")
#print "=> retCode = " + str(retCode) # to check the value returned by matlab
#if retCode == 0 : remove('methlabs_tmp_' + filename) #Remove the matlab original script if no error
exit( retCode )

