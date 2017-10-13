#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#MODULES STANDARDS
from __future__ import print_function
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import collections # pour "defaultdict"
from sys import exit, stderr
from os import path
from datetime import datetime
#MODULES A INSTALLER
import seb_CPA
import numpy as np
import scipy.io as sio #Permet d'importer/exporter des fichiers au format Matlab < 7.3 != hdf5
import matplotlib.pyplot as plt
#IMPORTS
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.ticker import LinearLocator

def printf (*args) :
	print(*args,end="")

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'Tests on AES Correlation Analysis Side Channel Attack Python Module.', formatter_class=ArgumentDefaultsHelpFormatter )
	# ARGUMENTS PASSES AU MODULE "seb_CPA"
	parser.add_argument( "-d", "--dataDir", help="Directory to read the data from.", default="../data" )
	parser.add_argument( "-p", "--pattern", help="Data file name pattern.", default="data-*.txt" )
	parser.add_argument( "-c", "--cipherTexts", help="Ciphertexts file name.", default="ciphertexts.txt" )
	parser.add_argument( "-t", "--plainTexts", help="Plaintexts file name.", default="plaintexts.txt" )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-q", "--quiet", help="Be quiet.", action='store_true', default = False )
	# ARGUMENTS DU SCRIPT LUI MEME
	parser.add_argument( "-r", "--reverse", help="Reverse the functionality of the script : read ciphertexts instead of plaintexts OR read lastRoundKey instead of cipherKey.", action='store_true', default = False )

	parser.add_argument( "--nfStart",help="Number of files to start from.",type=int, default = 50 )
	parser.add_argument( "--nfStep", help="Number of files to increment.", type=int, default = 25 )
	parser.add_argument( "--nfStop", help="Number of files to stop.",      type=int, default = 0 )

	parser.add_argument( "--nsStart",help="Number of samples to start", type=int, default = 1000 )
	parser.add_argument( "--nsStep", help="Number of samples increment",type=int, default = 500 )
	parser.add_argument( "--nsStop", help="Number of samples to stop",  type=int, default = 0 )

	parser.add_argument( "-V", "--version", help="Print version info.", action='store_true', default = False )
	scriptBaseName = parser.prog

	arguments = parser.parse_args()

def initScript() :
	global yearMonthDay, startTime
	yearMonthDay = datetime.today().strftime('%Y%m%d')

	if arguments.version :
		print("%s version %s" % (scriptBaseName,__version__) )
		exit()

	if not path.isdir( arguments.dataDir ) :
		print( "=> ERROR: The directory <" + arguments.dataDir + "> does not exists.", file = stderr )
		parser.print_usage()
		exit(2)

	startTime = datetime.now()

def main() :
	initArgs()
	initScript()
	seb_CPA.initArgs()
	seb_CPA.initAES()
	textsComplete = seb_CPA.importTexts()
	powerTracesComplete = seb_CPA.importTraces()

	if not arguments.nfStop :   arguments.nfStop   = textsComplete.shape[0]
	if not arguments.nsStop : arguments.nsStop = powerTracesComplete.shape[0]

	X = nbTextsRange    = np.arange( arguments.nfStart,   arguments.nfStop,   arguments.nfStep,   dtype = np.uint32 )
	Y = nbSamplesRange  = np.arange( arguments.nsStart, arguments.nsStop, arguments.nsStep, dtype = np.uint32 )
	Z = commonBytesArray= np.zeros( ( nbTextsRange.size, nbSamplesRange.size), dtype = np.uint8 )

	if arguments.reverse :
		expectedKey = bytearray.fromhex( 'F64E800BD1F9F0A523D54C24AD0297FD' )
		aes_CCA_model = "seb_CPA.aes_CCA_dec_model( texts, powerTraces, expectedKey )"
	else :
		expectedKey = bytearray.fromhex( '0123456789ABCDEF123456789ABCDEF0' )
		aes_CCA_model = "seb_CPA.aes_CCA_enc_model( texts, powerTraces, expectedKey )"

	totalTests = nbTextsRange.size * nbSamplesRange.size
	print( "=> Nombre de tests total a effectuer = %d" % totalTests )

	commonBytesDict = collections.defaultdict( dict ) # 2D dictionnary
	i = nbTestsDone = 0
	for nbTexts in nbTextsRange :
		texts = textsComplete[:nbTexts]
#			seb_CPA.printTexts(texts)
		j = 0
		for nbSamples in nbSamplesRange :
			printf( "=> nbTexts = %5d nbSamples = %5d " % (nbTexts,nbSamples) )
			powerTraces = powerTracesComplete[:nbSamples,:nbTexts]
			seb_CPA.tic()
			foundKey = eval( aes_CCA_model )
			intersection = foundKey[ foundKey == expectedKey ]
			commonBytesDict[nbTexts][nbSamples] = intersection.size
			commonBytesArray[i][j] = intersection.size
			printf( "nbCommonBytes = %2d remaining tests to do : %5d " % ( commonBytesDict[nbTexts][nbSamples], totalTests-nbTestsDone ) )
			seb_CPA.toc()
			j += 1
			nbTestsDone += 1
		i += 1

	myTime = datetime.today().strftime('%HH%M')
	outputDataFilePrefix = scriptBaseName.split('.')[0] + '_' + yearMonthDay + '_' + myTime
	X, Y = np.meshgrid( X, Y )

	matLabDic = {
		'nbTexts' : X,
		'nbSamples' : Y,
		'nbCommonBytes': Z
	}
	sio.savemat( outputDataFilePrefix +'.mat', matLabDic )

	fig = plt.figure()
	ax = plt.axes(projection='3d')

	print( "\n=> It took : " + str(datetime.now()-startTime) + " to finish the job.\n" )

	surface = ax.plot_surface(X, Y, Z, cmap=plt.cm.jet, rstride=1, cstride=1, linewidth=0)
	#ax.plot_surface(X, Y, Z, cmap=plt.cm.jet)

	# Customize the z axis.
#	ax.set_zlim(0, .16)
	ax.w_zaxis.set_major_locator(LinearLocator(6))

	fig.colorbar(surface, shrink=0.5, aspect=5)

	fig.savefig( outputDataFilePrefix + ".png", fig.dpi )
	fig.savefig( outputDataFilePrefix + ".svg", fig.dpi )
	fig.savefig( outputDataFilePrefix + ".pdf", fig.dpi )

	plt.show()

	exit()

if __name__ == '__main__': #Appel la fonction main ssi on ne fait pas d'import de ce script
	main()
