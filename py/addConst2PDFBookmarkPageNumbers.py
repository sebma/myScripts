#!/usr/bin/env python

import sys
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from re import search, sub

parser = ArgumentParser( description="Incremente les numeros de pages d'un index PDF d'une constante passee en parametre.", formatter_class=ArgumentDefaultsHelpFormatter )
parser.add_argument( "-c", "--constant", type = int, default = 1, help = "Constante a ajouter aux de pages de l'index PDF." )
parser.add_argument( "-f", "--first", type = int, default = 1, help = "A partir de quelle occurence commercer l'addition." )
parser.add_argument( "fileName", help="Nom du fichier d'index PDF." )

args = parser.parse_args()
counter = 0
#for line in sys.sdin.read() :
with open( args.fileName ) as FILE :
	for line in FILE :
		found=search( "BookmarkPageNumber:.*(\d+)", line )
		if found :
			counter += 1
			if counter >= args.first :
#				print sub( "(\d+)", str( int( r"\1") + args.constant ), line )
				print sub( "(\d+)", str( int( search( "(\d+)", line ).group() ) + args.constant ), line ),
			else :
				print line,
		else :
			print line,
