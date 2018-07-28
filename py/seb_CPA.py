#!/usr/bin/env python3
# coding: utf-8

#MODULES STANDARDS
from __future__ import print_function
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from sys import stderr, exit
import os, sys
from os import path, environ
from glob import glob #pour lister les fichiers selon une globbing pattern
import binascii # pour "hexlify"
from datetime import datetime #pour chronometrer
import types
import time
import inspect
from collections import OrderedDict

#MODULES A INSTALLER
import numpy as np #Pour le calcul matriciel
import pandas #pour importer les data
import IPython
from termcolor import cprint
#import scipy.io as sio #Permet d'importer des fichiers au format Matlab < 7.3 != hdf5

#from colors import red, blue, green #Module non installable sur Windows via conda

#from numba import jit
#@jit

def Print(*args, **kwargs) :
	if not arguments.quiet : print(*args, **kwargs)

def CPrint(*args, **kwargs) :
	if not arguments.quiet : cprint(*args, **kwargs)

def resetNumpyPrintOptions() :
	np.set_printoptions(edgeitems=3,infstr='inf',
	 linewidth=75, nanstr='nan', precision=8,
	 suppress=False, threshold=1000, formatter=None)

def isVector(array) :
	if array.ndim == 1 or array.shape[0] == 1 or array.shape[1] == 1 :
		return True
	else :
		return False

def numpyArrayInfo(array, arrayNAME) :
	Print("=> INFO: %s.shape = %s of %s" % ( arrayNAME, str(array.shape), array.dtype.name ) )
	if array.ndim == 1 or array.shape[0] == 1 or array.shape[1] == 1 :
		Print("=> INFO: %s[0] = %s, %s[end] = %s, (%s[1]-%s[0]) = %s" % ( arrayNAME, array[0], arrayNAME, array[-1], arrayNAME, arrayNAME, (array[1]-array[0]) ) )

	if   arguments.verbosity >= 2 :
		Print( "=> array :" )
		np.set_printoptions(edgeitems=9,linewidth=9*16 )
		for k in np.arange(array.shape[0]) : Print( array[k] )
	elif arguments.verbosity >= 3 :
		Print( "=> array :" )
		np.set_printoptions(threshold=np.nan,edgeitems=9,linewidth=9*16 )
		for k in np.arange(array.shape[0]) : Print( array[k] )
	resetNumpyPrintOptions()

def printNLogErrorString(string) :
	if not arguments.quiet : Print( string, file = sys.stderr)
#	if arguments.log : Print( string, file = logFileHandle)

def printNLogErrorAndExit(errorMessage, rc) :
	if errorMessage :
		(frame, filename, line_number, callerFunctionName, lines, index) = inspect.stack()[1]

	#	timestamp = datetime.now().strftime('%H:%M:%S') + str(datetime.now().microsecond)
		timestamp = str(datetime.now())[11:23]

		errorMessage = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + errorMessage
		exitMessage  = timestamp + " - [pid=" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "][lineno=" + str( line_number ) + "] - ERROR: " + "The script < " + scriptBaseName + " > exited with code <" + str(rc) + ">.\n"
		printNLogErrorString( errorMessage + "\n" + exitMessage )

		"""
		if arguments.log :
			Print( "=> Le fichier de log est: < " + logFileName + ">.\n", file = sys.stderr)
			logFileHandle.close()
"""
		exit(rc)

def listPythonModulesImported():
	modulesList = []
	for name, val in globals().items():
		if   isinstance(val, types.ModuleType):
			modulesList += [ val.__name__ ]
		elif isinstance(val, types.FunctionType):
			modulesList += [ sys.modules[val.__module__].__name__ ]
	return list(OrderedDict.fromkeys( modulesList ) )

def printExternalModulesVersions() :
#	import pip
#	installed_packages = pip.get_installed_distributions() # get_installed_distributions() has moved to pip.get_installed_distributions in pip v10+
	import pkg_resources
	installed_packages = [d for d in pkg_resources.working_set]

	packageVersions  = {package.key: package.version  for package in installed_packages}
	packageLocations = {package.key: package.location for package in installed_packages}

#	modules = list(set(sys.modules) & set(globals()))
	modules = sorted(listPythonModulesImported())
	for module in modules:
		moduleName = module.split('.')[0]
		if moduleName.lower() in packageVersions.keys() :
			if arguments.verbosity >= 2 :
				modulePATH = packageLocations[moduleName.lower()] + os.sep + moduleName if path.isdir( packageLocations[moduleName.lower()] ) else packageLocations[moduleName.lower()]
				Print( "=> Imported %s version %s, path = %s" % (moduleName , packageVersions[moduleName.lower()], modulePATH) )
			else :
				Print( "=> Imported %s version %s" % (moduleName , packageVersions[moduleName.lower()] ) )

def tic():
	#Homemade version of matlab tic and toc functions
	global startTime_for_tictoc
	startTime_for_tictoc = time.time()

def toc():
	if 'startTime_for_tictoc' in globals():
		print("Elapsed time is %.3f seconds. " % (time.time() - startTime_for_tictoc) )
	else:
		print("Toc: start time not set")

def totalTime() :
	Print( "\n=> Total time until now = " + str(datetime.now()-startTime) + "s." )

def initArgs() :
	global __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'AES Correlation Analysis Side Channel Attack.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument( "-d", "--dataDir", help="Directory to read the data from.", default="../../data" )
	parser.add_argument( "-D", "--debug", help="Debug the model with ipdb.", action='store_true', default = False )
	parser.add_argument( "-p", "--pattern", help="Data file name pattern.", default="data-*.txt" )
	parser.add_argument( "-c", "--cipherTexts", help="Ciphertexts file name.", default="ciphertexts.txt" )
	parser.add_argument( "-t", "--plainTexts", help="Plaintexts file name.", default="plaintexts.txt" )
	parser.add_argument( "-L", "--logTabes", help="Print AESExpTable, AESLogTable and Rcon tables and exit.", action='store_true', default = False )
	parser.add_argument( "-H", "--hammingWeightTable", help="Print the Hamming Weight Table and exit.", action='store_true', default = False )
	parser.add_argument( "-T", "--tables", help="Print sbox, invSbox, AESExpTable, AESLogTable and Rcon tables and exit.", action='store_true', default = False )
	parser.add_argument( "-K", "--roundKey", help="Print round keys according to a given cipherKey string.", default = None )
	parser.add_argument( "-r", "--reverse", help="Reverse the functionality of the script : read ciphertexts instead of plaintexts OR read lastRoundKey instead of cipherKey.", action='store_true', default = False )
	parser.add_argument( "-s", "--skipEmptyTriggers", help="TO DEBUG: Skip the first null trigger lines.", action='store_true', default = False )
	parser.add_argument( "-S", "--Sbox", help="Print Rijndael S-box and exit.", action='store_true', default = False )
	parser.add_argument( "--dec",  help="Print tables in decimal if this option is set.", action='store_true', default = False )
	parser.add_argument( "-k", "--AESKeySize", help="AES Key size in bits.", default=128, type=int )
	parser.add_argument( "-n", "--nbFiles", help="Number of data files to read", type=int, default = -1 )
	parser.add_argument( "-m", "--nbSamples", help="Number of samples to read", type=int, default = -1 )
#	parser.add_argument( "-m", "--nbMaxSamples", help="TO DO: Number of samples to read.", type=int, default = -1 )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-V", "--version", help="Print version info.", action='store_true', default = False )
#	parser.add_argument( "-V", "--version", help="Print version info.", action='version', version = '%(prog)s version ' + __version__ )
	parser.add_argument( "--mdh",  help="Print help in markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--md", help="Print output in markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--corrMethod1", help="Try corrMethod1 : NOT WORKING YET.", action='store_true', default = False )

	parser.add_argument( "-0", "--method0", help="Try importMethod0.", action='store_true', default = False )
	parser.add_argument( "-1", "--method1", help="Try importMethod1.", action='store_true', default = False )
	parser.add_argument( "-2", "--method2", help="Try importMethod2.", action='store_true', default = False )
	parser.add_argument( "-3", "--method3", help="Try importMethod3.", action='store_true', default = False )
	parser.add_argument( "-4", "--method4", help="Try importMethod4.", action='store_true', default = False )
	parser.add_argument( "-5", "--method5", help="Try importMethod5.", action='store_true', default = True )

	parser.add_argument( "-q", "--quiet", help="Be quiet.", action='store_true', default = False )

	return parser

def parseMyArguments(parser) :
	global scriptBaseName, arguments

	scriptBaseName = parser.prog
	arguments = parser.parse_args()
	if arguments.mdh :
		Print("<pre><code>")
		parser.print_help()
		Print("</code></pre>")
		exit()

	if arguments.roundKey : #Si K0 est passee en parametre, on calcule la longueur de la cle
		arguments.AESKeySize = len(arguments.roundKey) * 4 #4 bits par caractere hexadecimal

	if arguments.AESKeySize != 128 and arguments.AESKeySize != 192 and arguments.AESKeySize != 256 :
		Print( "=> ERROR: The only supported key sizes are 128, 192 and 256 bits.", file = stderr )
		exit(1)

	if arguments.md : Print("<pre><code>")

	if arguments.verbosity : print("=> INFO: arguments = %s" % arguments)

	return arguments

def Exit(retCode=0) :
	if arguments.md : Print("</code></pre>")
	exit(retCode)

def mySet_trace() : #Pour l'environement de DEV
	if arguments.debug : #Pour l'environement de DEV
		try :
			from ipdb import set_trace
		except Exception as why :
			Print("=> WARNING: %s, using pdb instead.\n" % why,file=sys.stderr)
			from pdb import set_trace
		set_trace()
	else :
		pass

def initialize_aes_sbox() :
	def ROTL8(x,shift) : return 0xff & ( ( (x) << (shift) ) | ( (x) >> (8 - (shift) ) ) )

	sbox = [None] * 256
	p = q = 1
	firstTime = True

	# loop invariant: p * q == 1 in the Galois field
	while p != 1 or firstTime : # To simulate a do/while loop
		# multiply p by 2
		p = p ^ (p << 1) ^ (0x1B if p & 0x80 else 0)
		p = p & 0xff

		# divide q by 2
		q ^= q << 1
		q ^= q << 2
		q ^= q << 4
		q ^= 0x09 if q & 0x80 else 0
		q = q & 0xff

		# compute the affine transformation
		xformed = q ^ ROTL8(q, 1) ^ ROTL8(q, 2) ^ ROTL8(q, 3) ^ ROTL8(q, 4)

		sbox[p] = xformed ^ 0x63
		firstTime = False

	# 0 is a special case since it has no inverse
	sbox[0] = 0x63

	return sbox

def AESGenTables() :
	global xtimeTable, AESLogTable, AESExpTable, sbox, sboxInv, rcon, hammingWeightOfByteTable

	sbox = np.asarray( initialize_aes_sbox(), dtype  = np.uint8 )
	sboxInv = np.zeros_like(sbox)
	sboxInv[ sbox ] = np.arange(valuesOfByte) # car sboxInv[ sbox[i] ] = i

	xtimeTable = np.asarray( xtimeTableGen(), dtype  = np.uint8 )

	AESExpTable = np.asarray( AESExpTableGen(), dtype  = np.uint8 )

#	AESLogTable = np.zeros( valuesOfByte, dtype  = np.uint16) # car dans AESMultiplicationInGF(x,y) Log(x)+Log(y) peut depasser 255, c'est ensuite qu'on fait le modulo 255
	AESLogTable = np.zeros_like( AESExpTable )
	AESLogTable[ AESExpTable ] = np.arange(valuesOfByte) # car Log(Exp(i)) = i

	rcon = np.asarray( RconTableGen(), dtype  = np.uint8 )

	hammingWeightOfByteTable = np.asarray( hammingWeightOfByteTableGen() , dtype  = np.uint8 )

def initAES() :
	global Nr, Nb, Nk, wordSizeInBytes
	global valuesOfByte, keyByteSize, roundKeys

	global pythonVersion, pid
	pythonVersion = ".".join(map(str, sys.version_info[:3]))

	pid = str( os.getpid() )

	Print("%s version %s" % (scriptBaseName,__version__) )

	if arguments.verbosity >= 3 :
		Print("=> Current environment variables loaded :\n")
		for key,value in sorted(environ.items()) :
			if 'BASH_FUNC_' not in key :
				Print("=> %s = %s" %(key,value))
		Print()

	if arguments.verbosity :
		if arguments.version or arguments.verbosity >=1 :
			printExternalModulesVersions()
			if arguments.verbosity >= 2 :
				Print("\nUsing Python version %s" % sys.version )
				Print("Python  : " + sys.executable)
			else :
				Print("\nUsing Python version %s" % pythonVersion )

	if arguments.version : exit()

	wordSizeInBytes = 4 # Number of bytes in a word : mots de 4 octets
	wordSizeInBits =  8 * wordSizeInBytes # Number of bits in a word

	Nb = 4 # Number of words in input, output and state blocks
	Nk = arguments.AESKeySize // wordSizeInBits # Number of words in key
	Nr = Nk + 6 # Number of rounds

	keyByteSize = wordSizeInBytes * Nk # Number of bytes in a key : 16, 24 or 32 bytes
	valuesOfByte = 1<<8 #Nombre de valeurs possibles prisent par un octet

	AESGenTables()

	if arguments.verbosity == 4 or arguments.tables :
		if not arguments.dec : np.set_printoptions(formatter={ 'int':lambda x:'0x%02X' % x }, linewidth=85 )
		Print( "=> AESExpTable :\n" + str( AESExpTable.reshape(-1,16) ) )
		Print( "=> AESLogTable :\n" + str( AESLogTable.reshape(-1,16) ) )
		Print( "=> sbox :\n" + str( sbox.reshape(-1,16) ) )
		Print( "=> sboxInv :\n" + str( sboxInv.reshape(-1,16) ) )
		Print( "=> rcon :\n" + str( rcon.reshape(-1,16) ) )
		resetNumpyPrintOptions()

	if arguments.Sbox :
		if not arguments.dec : np.set_printoptions(formatter={ 'int':lambda x:'0x%02X' % x }, linewidth=85 )
		Print( "=> sbox :\n" + str( sbox.reshape(-1,16) ) )
		Print( "=> sboxInv :\n" + str( sboxInv.reshape(-1,16) ) )
		resetNumpyPrintOptions()

	if arguments.logTabes :
		if not arguments.dec : np.set_printoptions(formatter={ 'int':lambda x:'0x%02X' % x }, linewidth=85 )
		Print( "=> AESExpTable :\n" + str( AESExpTable.reshape(-1,16) ) )
		Print( "=> AESLogTable :\n" + str( AESLogTable.reshape(-1,16) ) )
		Print( "=> rcon :\n" + str( rcon.reshape(-1,16) ) )
		resetNumpyPrintOptions()

	if arguments.hammingWeightTable :
		Print( "=> hammingWeightOfByteTable :\n" + str( hammingWeightOfByteTable.reshape(-1,16) ) )

	if arguments.roundKey :
		if arguments.reverse :
			lastRoundKeys = np.asarray( bytearray.fromhex( arguments.roundKey ) )

#			roundKeys = invKeyExpension( lastRoundKeys )
			roundKeys = revertKeyExpension( lastRoundKeys )
			if   lastRoundKeys.size == 16 :
				cipherKey = roundKeys[0]
			elif lastRoundKeys.size == 24 :
				cipherKey = np.concatenate( ( roundKeys[0], roundKeys[1][:8] ) )
			elif lastRoundKeys.size == 32 :
				cipherKey = np.concatenate( ( roundKeys[0], roundKeys[1] ) )
			printRoundKeys(roundKeys)
			Print( '\n=> cipherKey = %s' % byteArray2HexString( cipherKey ) )
		else :
			roundKeys = keyExpension( bytearray.fromhex( arguments.roundKey ) )
			printRoundKeys(roundKeys)

	if arguments.tables or arguments.Sbox or arguments.logTabes or arguments.roundKey or arguments.hammingWeightTable : Exit()

	if not path.isdir( arguments.dataDir ) :
		Print( "=> ERROR: The directory <" + arguments.dataDir + "> does not exists.", file = stderr )
		parser.print_usage()
		exit(2)

def xtime(a) : #Multiplication par x dans GF(2**8)
	generator = 0x011b #Pour le modulo m(x) (cf. FIPS 197 §4.2.1 p.11)
	# Si le 8eme bit = 1 (cf. FIPS 197 §4.2.1 p.11)
	result = (a << 1) ^ generator & 0xff if (a & 0x80) else (a<<1)
	return result & 0xff #Le resultat est modulo 2**8

def xtimeTableGen() :
	myXtimeTAB = [0] * valuesOfByte
	for i in range(valuesOfByte) :
		myXtimeTAB[i] = xtime(i)

	return myXtimeTAB

def AESExpTableGen() :
	AESExpTable = [0] * valuesOfByte
	AESExpTable[0] = 1 #car Exp(0) = 1
	for i in range(1,valuesOfByte) :
#		AESExpTable[i] = AESExpTable[i-1] ^ xtime( AESExpTable[i-1] ) #La valeur est la resultante de la multiplication par 3 dans GF(2**8)
		AESExpTable[i] = AESExpTable[i-1] ^ xtimeTable[ AESExpTable[i-1] ] #La valeur est la resultante de la multiplication par 3 dans GF(2**8)

	return AESExpTable

def RconTableGen() :
	Rcon = [0] * valuesOfByte
	Rcon[0] = 0x8d
	for i in range(1,valuesOfByte) :
#		Rcon[i] = xtime( Rcon[i-1] )
		Rcon[i] = xtimeTable[ Rcon[i-1] ]

	return Rcon

def hammingWeightOfByteTableGen():
	return [ bin(i).count('1') for i in range(valuesOfByte) ]

def AESMultiplicationInGF(x,y) :
	if x == 0 or y == 0 :
		result = 0
	else :
		x = x & 0xff
		y = y & 0xff
#		result = AESExpTable[ np.uint8( AESLogTable[x] + AESLogTable[y] ) ]
		result = AESExpTable[ ( AESLogTable[x] + AESLogTable[y] ) % 0xff ]

	return result

def mixColum(column) :
	result = np.zeros_like( column, dtype = np.uint8 )
	result[0] =	AESMultiplicationInGF(2,column[0]) ^ AESMultiplicationInGF(3,column[1]) ^ \
				column[2] ^ column[3]
	result[1] =	column[0] ^ AESMultiplicationInGF(2,column[1]) ^ AESMultiplicationInGF(3,column[2]) ^ \
				column[3]
	result[2] =	column[0] ^ column[1] ^ AESMultiplicationInGF(2,column[2]) ^ \
				AESMultiplicationInGF(3,column[3])
	result[3] =	AESMultiplicationInGF(3,column[0]) ^ column[1] ^ column[2] ^ \
				AESMultiplicationInGF(2,column[3])

	return result

def invMixColum(column) :
	result = np.zeros_like( column, dtype = np.uint8 )
	result[0] =	AESMultiplicationInGF(0xe,column[0]) ^ AESMultiplicationInGF(0xb,column[1]) ^ \
				AESMultiplicationInGF(0xd,column[2]) ^ AESMultiplicationInGF(9,column[3])
	result[1] =	AESMultiplicationInGF(9,column[0]) ^ AESMultiplicationInGF(0xe,column[1]) ^ \
				AESMultiplicationInGF(0xb,column[2]) ^ AESMultiplicationInGF(0xd,column[3])
	result[2] =	AESMultiplicationInGF(0xd,column[0]) ^ AESMultiplicationInGF(9,column[1]) ^ \
				AESMultiplicationInGF(0xe,column[2]) ^ AESMultiplicationInGF(0xb,column[3])
	result[3] =	AESMultiplicationInGF(0xb,column[0]) ^ AESMultiplicationInGF(0xd,column[1]) ^ \
				AESMultiplicationInGF(9,column[2]) ^ AESMultiplicationInGF(0xe,column[3])

	return result

def mixColums(state) :
	result = np.zeros_like(state, dtype = np.uint8)
	for i in range(state.shape[1]) :
		column = state[:,i] #On recupere toutes les lignes de la colonne i
		result[i] = mixColum(column)

	return result

def invMixColums(state) :
	result = np.zeros_like(state, dtype = np.uint8)
	for i in range(state.shape[1]) :
		column = state[:,i] #On recupere toutes les lignes de la colonne i
		result[i] = invMixColum(column)

	return result

def printRoundKeys(roundKeys) :
	for i,roundKey in enumerate(roundKeys) :
		Print( '=> roundKeys[%2d] = %s' % ( i,byteArray2HexString( roundKey ) ) )

def byteArray2HexString(array) :
	myStr = binascii.hexlify(array).upper()
	myStr = myStr.decode("ascii") #Pour Python3 : convertit le type "bytes" en "string"
	myStr = ' '.join( [ myStr[i:i+8] for i in range(0, len(myStr), 8) ] )

	return myStr

# rotate word 1 byte to the left
def RotWord(row) :
	if type(row) is list :
		return  rotateList(row,1)
	elif isinstance(row,np.ndarray) :
		return rotateArray(row,1)

def F(I,word) :
	temp = word
	if  I % (4*Nk) == 0 :
		temp = sbox[ RotWord(temp) ]
		temp[0] = temp[0] ^ rcon[ I//(4*Nk) ] #cf Appendix A1 du FIPS 197
	elif ( Nk > 6 ) and ( I % (4*Nk) == 16 ) :
		temp = sbox[temp]

	return temp

def keyExpension(cipherKey) :
	byte = np.zeros( 4 * Nb * (Nr+1), dtype = np.uint8 ) #tableau de bytes

	byte[0:4*Nk] = cipherKey #On recopie la cipherKey au debut du tableau
	for I in range(4*Nk, 4 * Nb * (Nr+1), 4 ) : # 4*Nk < I < 4 * Nb * (Nr+1)
		byte[I:I+4] = byte[I-4*Nk:I-4*Nk+4] ^ F(I,byte[I-4:I])

	return byte.reshape(Nr+1,-1) #On obtient un tableau de Nr + 1 clefs

def revertKeyExpension(lastRoundKeys) :
	# https://crypto.stackexchange.com/a/50546/50150
	byte = np.zeros( 4 * Nb * (Nr+1), dtype = np.uint8 ) #tableau de bytes

	byte[-4*Nk:] = lastRoundKeys #On recopie la/les deux cle(s) a la fin du tableau
	for J in range(4 * Nb * (Nr+1) - 4*Nk - 4, -1, -4 ) : # 4 * Nb * (Nr+1) - 4*Nk - 4  > J > -1
		byte[J:J+4] = byte[J+4*Nk:J+4*Nk+4] ^ F(J+4*Nk,byte[J+4*Nk-4:J+4*Nk])

	return byte.reshape(Nr+1,-1) #On obtient un tableau de Nr + 1 clefs

def invKeyExpension(key) :
	keys = keyExpension(key)
	roundKeys = np.zeros_like(keys)
	roundKeys[0] = keys[0]
	for i,roundKey in enumerate( keys[1:], 1 ) :
		roundKeys[i] = invMixColums( roundKey.reshape(Nb,-1) ).reshape( 4*Nb ) #CF. figure 15 page 25 du FIPS 197

	return roundKeys

def xor(x,y) : #xor de deux vecteurs et retourne une matrice, operation non commutative pour des vecteurs
#	return [ [ i^j for j in y ] for i in x ] #plus lisible que 'map' :)
	return x[:,np.newaxis] ^ y

def subBytes( val, sbox ) :
	lsbMask = 15  #0x0F
	msbMask = 240 #0xF0
	l = val & lsbMask
	m = ( val & msbMask ) >> 4
	return sbox[m][l]

def subBytesMat( matrix ) :
	rows = len(matrix)
	cols = len(matrix[0])

#	return [ [ subBytes( matrix[i][j] ) for j in range(cols) ] for i in range(rows) ]
	return [ [ sbox[ matrix[i][j] ] for j in range(cols) ] for i in range(rows) ]

def subBytesMat2( matrix ) :
	sBoxFunction = lambda x: sbox[x]
	vsBox = np.vectorize(sBoxFunction)

	return vsBox(matrix)

def addRoundKey(bytes,key) :
	result = xor(bytes,key)
	return result

def hammingWeightMat( matrix ) :
	rows, cols = matrix.shape
#	return [ [ hammingWeight( matrix[i][j] ) for j in range(cols) ] for i in range(rows) ]
#	return [ [ bin( matrix[i][j] ).count("1") for j in range(cols) ] for i in range(rows) ]
	return [ [ hammingWeightOfByteTable[ matrix[i][j] ] for j in range(cols) ] for i in range(rows) ]

def hammingWeight(myInt) :
	weight = bin(myInt).count("1")
	return weight

def corr_coeff(A,B) :
	# Get number of rows in either A or B
	N = B.shape[0]

	# Store columnw-wise in A and B, as they would be used at few places
	sA = A.sum(0)
	sB = B.sum(0)

	# Basically there are four parts in the formula. We would compute them one-by-one
	p1 = N*np.einsum('ij,ik->kj',A,B)
	p2 = sA*sB[:,np.newaxis]
	p3 = N*((B**2).sum(0)) - (sB**2)
	p4 = N*((A**2).sum(0)) - (sA**2)

	# Finally compute Pearson Correlation Coefficient as 2D array
	pcorr = ((p1 - p2)/np.sqrt(p4*p3[:,np.newaxis]))

	# Get the element corresponding to absolute argmax along the columns
#	out = pcorr[np.nanargmax(np.abs(pcorr),axis=0),np.arange(pcorr.shape[1])]

	return pcorr

def corr2_coeff(A,B) :
	# https://stackoverflow.com/a/30143754/5649639
	result = np.zeros( (A.shape[0],B.T.shape[1]) )
	# Rowwise mean of input arrays & subtract from input arrays themeselves
	A_mA = A - A.mean(1)[:,np.newaxis]
	B_mB = B - B.mean(1)[:,np.newaxis]

	# Sum of squares across rows
	ssA = (A_mA**2).sum(1);
	ssB = (B_mB**2).sum(1);

	# Finally get corr coeff

	numerator = np.dot(A_mA,B_mB.T)
	denominator = np.sqrt( np.dot( ssA[:,np.newaxis], ssB[None] ) )
	try :
		result = numerator/denominator
	except Exception as why :
		Print("=> WARNING: %s" % why,file=sys.stderr)

#	return np.dot(A_mA,B_mB.T)/np.sqrt(np.dot(ssA[:,np.newaxis],ssB[None]))
	return result

def MyWho() : #A completer et a tester
	Print( [v for v in globals().keys() if not v.startswith('_')] )

def myLocals() : #A completer et a tester
#	Print( [v for v in globals().keys() if not v.startswith('_')] )
	excludedTypes = [ types.FunctionType, types.ModuleType, types.ClassType, types.BuiltinFunctionType, types.SimpleNamespace ]
	for key, value in globals().iteritems() :
		if not key.startswith('_') :
#			mySet_trace()
			if type(value) not in excludedTypes :
				Print("=> %s = %s" % (key,value))

def whosMy(*args): #A completer et a tester
	sequentialTypes = [dict, list, tuple]
	for var in args:
		t=type(var)
		if t == np.ndarray:
			Print( type(var),var.dtype, var.shape )
		elif t in sequentialTypes:
			Print( type(var), len(var) )
		else:
			Print( type(var) )

def PrintFrame():
	callerframerecord = inspect.stack()[1]    # 0 represents this line
                                              # 1 represents line at caller
	callingFrame = callerframerecord[0]
	info = inspect.getframeinfo(callingFrame)
	Print("==> In script : <%s>" % info.filename)                       # __FILE__     -> Test.py
	Print("==> In function : <%s>" % info.function)                       # __FUNCTION__ -> Main
	Print("==> At line : %s" % info.lineno)                         # __LINE__     -> 13

#Rotation de tous les colonnes d'une ligne de n positions vers la gauche
def rotateList(row, n) :
	return row[n:]+row[:n]

#Rotation de tous les colonnes d'une ligne de n positions vers la gauche
def rotateArray(row, n) :
#	return np.roll(row,n) #10x plus lent
	return np.concatenate( ( row[n:], row[:n] ) )

def shiftRowsInv( matrix ) :
	try :
		matrix_Nx4 = matrix.reshape(-1,4) #On transforme la matrice pour qu'elle ait 4 colonnes
		m = np.zeros_like(matrix_Nx4)
		m[0] = matrix_Nx4[0] #On recopie la premiere ligne tel quel
		for i, row in enumerate(matrix_Nx4[1:],1) :
			if i % 4 :
				m[i] = rotateArray(row,-i) #Rotation de tous les colonnes d'une ligne de i positions vers la droite
			else : #Alors on recopie les lignes 0,4,8,12, ...
				m[i] = row
	except Exception as why :
		Print("=> ERROR: %s" % why,file=sys.stderr)
		PrintFrame()
		exit(-3)

	return m.reshape(matrix.shape)

def aes_CCA_dec_model( texts, powerTraces, expectedLastRoundKey ) :
	finalKeyStr = ''
	subKeyVector = np.arange( valuesOfByte, dtype = np.uint8 ).reshape(valuesOfByte,1) #vecteur des valeurs possibles d'un octet de la sous-cle, taille = (256,1)
	nbInversedSubKeys = 0
	keyFound = np.zeros(keyByteSize, dtype  = np.uint8)

	if arguments.verbosity :
		Print("=> INFO: powerTraces.shape = %s of %s" % ( str(powerTraces.shape), powerTraces.dtype ) )
		Print("=> INFO: texts.shape = " + str(texts.shape) + "\n" )

	try :
		for k in range( keyByteSize ) : #On parcour matrice de texts de bytes octet/octet
			if arguments.verbosity >= 2 : tic() ; Print('\n=> Feeding the bytes vector ...')
			byteVector = texts[:,k] #On recupere toute les lignes de la colonne k

			if arguments.verbosity >= 2 : toc() ; Print('=> Calculating the XOR of both bytes and subKeyVector vectors ...')
			state = addRoundKeyOutput = subKeyVector ^ byteVector #matrice attendue : valuesOfByte x nbTexts

			if arguments.verbosity >= 2 : toc() ; Print('=> Calculating the Hamming weigh of the resulting matrix ...\n')
			hW = hammingWeightOfByteTable[ state ]

			if arguments.verbosity and k == 0 :
				Print("=> INFO: subKeyVector.shape = " + str(subKeyVector.shape) )
				Print("=> INFO: byteVector.shape = " + str(byteVector.shape) )
				Print("=> INFO: addRoundKeyOutput.shape = " + str(addRoundKeyOutput.shape) )
				Print("=> INFO: hW.shape = " + str(hW.shape) + "\n" )

			if arguments.verbosity and k == 0 : tic(); Print('\n=> Calculating the correlation matrix between powerTraces = %s and hW = %s ...' % ( str(powerTraces.shape), str(hW.shape) ) )
			if arguments.corrMethod1 :	myCorrelationMatrix =  corr_coeff( powerTraces, hW )
			else :						myCorrelationMatrix = corr2_coeff( powerTraces, hW ) #Methode par defaut

			if arguments.verbosity and k == 0 :
				toc()
				Print("\n=> INFO: myCorrelationMatrix.shape = " + str(myCorrelationMatrix.shape) + "\n" )

#			myCorrelationMatrix = abs( myCorrelationMatrix )

			if arguments.verbosity >= 2 : toc() ; Print('=> Getting the index where the correlation is the highest ...')
			keyFound[k] = np.nanargmax( myCorrelationMatrix ) % valuesOfByte

			if arguments.verbosity : Print()

			subKeyFoundHex = '%02X' % keyFound[k]
			Print('=> The subKeyFound is ' + subKeyFoundHex)
			if arguments.verbosity :
				currentCorelation = np.nanmax(myCorrelationMatrix)
				if currentCorelation < .4 :
#					Print( red( "=> Correlation max = %f" % currentCorelation, style='bold+blink' ) )
					CPrint( "=> Correlation max = %f" % currentCorelation, 'red', attrs=['bold','blink'] )
				else :
#					Print( blue( "=> Correlation max = %f" % currentCorelation ) )
					CPrint( "=> Correlation max = %f" % currentCorelation, 'blue' )
#				if valuesOfByte - 1 - keyFound[k] == expectedLastRoundKey[k] :
				if (valuesOfByte-1) ^ keyFound[k] == expectedLastRoundKey[k] :
					nbInversedSubKeys += 1
#					Print(green("=> WARNING: The key found is the two's complement of the expected key (k = %d)." % k))
					CPrint( "=> WARNING: The key found is the two's complement of the expected key (k = %d)." % k, 'green')
					Print('=> expectedSubKey = ' + format(expectedLastRoundKey[k], "08b"))
					Print('=> subKeyFound    = ' + format(keyFound[k], "08b"))
			finalKeyStr = finalKeyStr + subKeyFoundHex
	except Exception as why :
		Print("=> ERROR: %s" % why,file=sys.stderr)
		PrintFrame()
		if arguments.debug :
			IPython.embed()
			"""
			ipython = IPython.get_ipython()
			ipython.magic("whos ndarray")
"""
		exit(-2)

	if arguments.verbosity and nbInversedSubKeys :
#		Print(green("\n=> WARNING : Found %d subkeys that are the two's complement of their expected subkey counterparts." % nbInversedSubKeys))
		CPrint("\n=> WARNING : Found %d subkeys that are the two's complement of their expected subkey counterparts." % nbInversedSubKeys, 'green')

	return keyFound

def aes_CCA_enc_model( texts, powerTraces, expectedRound0Key ) :
	finalKeyStr = ''
	subKeyVector = np.arange( valuesOfByte, dtype = np.uint8 ).reshape(valuesOfByte,1) #vecteur des valeurs possibles d'un octet de la sous-cle, taille = (256,1)
	nbInversedSubKeys = 0
	keyFound = np.zeros(keyByteSize, dtype  = np.uint8)

	if arguments.verbosity :
		Print("=> INFO: powerTraces.shape = " + str(powerTraces.shape) )

	try :
		for k in range( keyByteSize ) : #On parcour matrice de texts de bytes octet/octet
			if arguments.verbosity >= 2 : tic() ; Print('\n=> Feeding the bytes vector ...')
			byteVector = texts[:,k] #On recupere toute les lignes de la colonne k

			if arguments.verbosity >= 2 : toc() ; Print('=> Calculating the XOR of both bytes and subKeyVector vectors ...')
			state = addRoundKeyOutput = subKeyVector ^ byteVector #matrice attendue : valuesOfByte x nbTexts

			if arguments.verbosity >= 2 : toc() ; Print('=> Doing the subBytes using the sbox ...')
			state = sbox[ state ]

			if arguments.verbosity >= 2 : toc() ; Print('=> Calculating the Hamming weigh of the resulting matrix ...\n')
			hW = hammingWeightOfByteTable[ state ]

			if arguments.verbosity and k == 0 :
				Print("=> INFO: subKeyVector.shape = " + str(subKeyVector.shape) )
				Print("=> INFO: byteVector.shape = " + str(byteVector.shape) )
				Print("=> INFO: addRoundKeyOutput.shape = " + str(addRoundKeyOutput.shape) )
				Print("=> INFO: hW.shape = " + str(hW.shape) + "\n" )

			if arguments.verbosity and k == 0 : tic(); Print('\n=> Calculating the correlation matrix between powerTraces = %s and hW = %s ...' % ( str(powerTraces.shape), str(hW.shape) ) )
			if arguments.corrMethod1 :	myCorrelationMatrix =  corr_coeff( powerTraces, hW )
			else :					myCorrelationMatrix = corr2_coeff( powerTraces, hW ) #Methode par defaut

			if arguments.verbosity and k == 0 :
				toc()
				Print("\n=> INFO: myCorrelationMatrix.shape = " + str(myCorrelationMatrix.shape) + "\n" )

	#		myCorrelationMatrix = abs( myCorrelationMatrix )

			if arguments.verbosity >= 2 : toc() ; Print('=> Getting the index where the correlation is the highest ...')
			keyFound[k] = np.nanargmax( myCorrelationMatrix ) % valuesOfByte

			if arguments.verbosity : Print()

			subKeyFoundHex = '%02X' % keyFound[k]
			Print('=> The subKeyFound is ' + subKeyFoundHex)
			if arguments.verbosity :
				currentCorelation = np.nanmax(myCorrelationMatrix)
				if currentCorelation < .4 :
	#				Print( red( "=> Correlation max = %f" % currentCorelation, style='bold+blink' ) )
					CPrint( "=> Correlation max = %f" % currentCorelation, 'red', attrs=['bold','blink'] )
				else :
	#				Print( blue( "=> Correlation max = %f" % currentCorelation ) )
					CPrint( "=> Correlation max = %f" % currentCorelation, 'blue' )
	#			if valuesOfByte - 1 - keyFound[k] == expectedRound0Key[k] :
				if (valuesOfByte-1) ^ keyFound[k] == expectedRound0Key[k] :
					nbInversedSubKeys += 1
	#				Print(green("=> WARNING: The key found is the two's complement of the expected key (k = %d)." % k))
					CPrint( "=> WARNING: The key found is the two's complement of the expected key (k = %d)." % k, 'green')
					Print('=> expectedSubKey = ' + format(expectedRound0Key[k], "08b"))
					Print('=> subKeyFound    = ' + format(keyFound[k], "08b"))
			finalKeyStr = finalKeyStr + subKeyFoundHex

	except Exception as why :
		Print("=> ERROR: %s" % why,file=sys.stderr)
		PrintFrame()
		if arguments.debug :
			IPython.embed()
			"""
			ipython = IPython.get_ipython()
			ipython.magic("whos ndarray")
"""
		exit(-2)

	if arguments.verbosity and nbInversedSubKeys :
#		Print(green("\n=> WARNING : Found %d subkeys that are the two's complement of their expected subkey counterparts." % nbInversedSubKeys))
		CPrint("\n=> WARNING : Found %d subkeys that are the two's complement of their expected subkey counterparts." % nbInversedSubKeys, 'green')

	return keyFound

def importTexts() :
	global nbTexts #Nombre de texte effectivement lu

	if arguments.reverse :
		fileName = arguments.dataDir + os.sep  + arguments.cipherTexts
	else :
		fileName = arguments.dataDir + os.sep  + arguments.plainTexts

	print("=> Reading : " + fileName )
	if os.stat( fileName ).st_size == 0 :
		Print("=> ERROR : The size of the file " + fileName + " is 0.", file=stderr)
		exit(3)

	texts = []
	with open( fileName ) as FILE :
		for nbRead,line in enumerate(FILE,1) :
			line = bytearray.fromhex( line.rstrip() ) # car chaque element se termine par '\n'
			texts.append( line )
			#Si arguments.nbFiles est positionne, on s'arretera de lire lorsque le nombre de texte lu nbRead sera = arguments.nbFiles
			if nbRead == arguments.nbFiles : break

	nbTexts = nbRead #Nombre de textes effectivement lus
	texts = np.asarray( texts )

	return texts

def printTexts(texts) :
	if arguments.verbosity :
		Print("=> INFO : texts.shape = %s of %s" % (str(texts.shape), str(texts.dtype) ) )
		if arguments.verbosity == 2 :
			Print( "=> texts :\n" )
			np.set_printoptions(edgeitems=8,formatter={ 'int':lambda x:'0x%02X' % x }, linewidth=85 )
			Print(texts)
		elif arguments.verbosity >=3 :
			Print( "=> texts :\n" )
			np.set_printoptions(threshold=np.nan,edgeitems=8,formatter={ 'int':lambda x:'0x%02X' % x }, linewidth=120 )
			Print(texts)
		resetNumpyPrintOptions()

def importTraces() :
	print("=> Reading : " + arguments.dataDir + os.sep  + arguments.pattern )
	cwd = os.getcwd()
	try :
		os.chdir( arguments.dataDir )

		dataFileList = sorted( glob( arguments.pattern ) )
		nbDataFiles = len(dataFileList)
		if arguments.nbFiles > 0 and arguments.nbFiles < nbDataFiles : # si arguments.nbFiles est positionne, on ne liera que les nbFiles premiers datasamples
			dataFileList = dataFileList[:arguments.nbFiles]

		nbDataFilesRead = len(dataFileList)
		if not nbDataFilesRead :
			printNLogErrorAndExit("Could not find any "+arguments.pattern+" files, please double check and give the correct data filename pattern.", rc=5 )

		amplitudes = []
		global nbLinesSkipped, startTime

		startTime = datetime.now()
	#	colnames = ['time','trigger','amplitude']
		firstNonZero = -1 #Valeur qui permettra de tester si firstNonZero a deja ete calcule
		i = 0
		method0 = method1 = method2 = method3 = method4 = method5 = False
		if   arguments.method0 :
			method0 = True
			Print( "=> INFO: Using np.loadtxt() method to import text data ..." )
		elif arguments.method1 :
			method1 = True
			Print( "=> INFO: Using open+readlines() method to import text data ..." )
		elif arguments.method2 :
			method2 = True
			Print( "=> INFO: Using open+readlines+zip+map() method to import text data ..." )
		elif arguments.method3 :
			method3 = True
			Print( "=> INFO: Using csv.reader() method to import text data ..." )
		elif arguments.method4 :
			method4 = True
			Print( "=> INFO: Using dask.dataframe.read_csv() method to import text data ..." )
		elif arguments.method5 :
			method5 = True
			Print( "=> INFO: Using pandas.read_csv() method to import text data ..." )

#		method0 = True #Positionner la methodi a True pour forcer la methode d'import des data textes
		firstFile = True
		firstNonZeroArray = np.empty(nbDataFilesRead)
		for dataFileName in dataFileList :
			if arguments.verbosity >= 3 :
				Print( "=> dataFileName = %s" % dataFileName )

			#Method0
			if method0 : time1, trigger1, amplitude1 = np.loadtxt( dataFileName, unpack = True ) # environ 1 minute, trop lent

			#Method1
			#Environ 7.5s pour lire un seule colonne de 500 fichiers
			if method1 :
				trigger1, amplitude1 = [],[]
				with open(dataFileName) as FILE : lines = FILE.readlines()
				for line in lines :
	#				trigger1.append(   int( line.split()[1] ) )
					amplitude1.append( int( line.split()[2] ) )

			#Method2
			#Environ 20s pour 500 fichiers
			if method2 :
				with open(dataFileName) as FILE : lines = FILE.readlines()
				time1, trigger1, amplitude1 = zip( *( [ map( int, line.split() ) for line in lines ] ) )

			if method3 :
			#Methode 3
			#Environ 15s pour lire une colonne de 500 fichiers et 20s pour lire 2 colonnes
				with open(dataFileName) as FILE :
					reader = csv.reader(FILE,delimiter='\t', skipinitialspace=True)
					for j,column in enumerate( zip(*reader) ):
						if j == 1 : trigger1   = [ int(col) for col in column ]
						if j == 2 : amplitude1 = [ int(col) for col in column ]

			#Method 4
			#Environ 4s pour 500 fichiers
			if method4 :
				import dask.dataframe
				df = dask.dataframe.read_csv(urlpath = dataFileName, delim_whitespace=True, skipinitialspace=True, names = ['time','trigger','amplitude'] )
				amplitude1 = df['amplitude'].values

			#Method 5
			if method5 :
				df = pandas.read_csv( dataFileName, delim_whitespace=True, skipinitialspace=True, names = ['time','trigger','amplitude'] )
				trigger1 = df[ 'trigger' ].values

				if arguments.skipEmptyTriggers :
					firstNonZeroArray[i] = np.argmax( trigger1 > 0 ) #On fait ce calcul qu'une seule fois pour avoir le meme nombre de colonnes dans toute la matrice finale : amplitudes
					i += 1
					amplitude1 = df['amplitude'].values #On prends tout pour l'instant et a la fin ou "coupera"
		#			nbLinesSkipped = 0
		#			firstNonZero = 0
		#			if firstNonZero == -1 : firstNonZero = np.argmax( trigger1 > 0 ) #On fait ce calcul qu'une seule fois pour avoir le meme nombre de colonnes dans toute la matrice finale : amplitudes
		#			amplitude1 = df['amplitude'].values[ firstNonZero: ]
		#			if arguments.verbosity and firstNonZero : Print( "=> INFO : " + str(firstNonZero) + " null trigger lines skipped in " + dataFileName + " ...", file = stderr )
		#			nonZeroValuesIndex = trigger1.nonzero()[0]
		#			amplitude1 = df.amplitude[ nonZeroValuesIndex ].values
		#			amplitude1 = df['amplitude'].values[ trigger1 >0 ] #Ne marche car le nombre de valeurs ignorees change d'un fichier a l'autre
		#			nbLinesSkipped = len( trigger1 ) - len( amplitude1 )
		#			if arguments.verbosity and nbLinesSkipped : Print( "=> INFO : " + str( nbLinesSkipped ) + " null trigger lines skipped in " + dataFileName + " ...", file = stderr )
				else :
					if arguments.nbSamples != -1 :
						try :
							amplitude1 = df['amplitude'].values[:arguments.nbSamples]
						except :
							amplitude1 = df['amplitude'].values
					else :
						amplitude1 = df['amplitude'].values

			if firstFile and arguments.verbosity >= 3 :
				np.set_printoptions(edgeitems=9,linewidth=9*16 )
				Print( np.asarray( amplitude1 ) )
				resetNumpyPrintOptions()
				firstFile = False

			amplitudes.append( amplitude1 ) #matrix nbFiles x nbSamples

		if arguments.skipEmptyTriggers :
			minNbLinesSkipped = np.nanmin(firstNonZeroArray)
			if minNbLinesSkipped :
				pass #On prends un sous-ensemble de amplitudes

	except (Exception,KeyboardInterrupt) as why :
		if isinstance(why, KeyboardInterrupt) :
			Print("=> ERROR: KeyboardInterrupt.",file=sys.stderr)
		else :
			Print("=> ERROR: %s : Quitting the debugger." % why,file=sys.stderr)
		os.chdir( cwd ) #Reviens au repertoire precedent dans l'environ de debug (ipython ou pdb)
		exit(4)

	os.chdir( cwd )

	amplitudes = np.asarray( amplitudes )
	if amplitudes.shape[0] == 0 or amplitudes.ndim == 1 or amplitudes.shape[1] == 0 :
#		Print("=> ERROR : The shape of the amplitudes matrix is not correct: amplitudes.shape = " + str(amplitudes.shape), file = sys.stderr )
		printNLogErrorAndExit("The shape of the amplitudes matrix is not correct: amplitudes.shape = " + str(amplitudes.shape), rc=6 )
#		exit(5)

	if arguments.verbosity :
		Print("\n=> INFO: amplitudes.shape = %s of %s" % (str(amplitudes.shape), amplitudes.dtype ) )
		if   arguments.verbosity >= 2 :
			Print( "=> amplitudes :" )
			np.set_printoptions(edgeitems=9,linewidth=9*16 )
			for k in np.arange(amplitudes.shape[0]) : Print( amplitudes[k] )
		elif arguments.verbosity >= 3 :
			Print( "=> amplitudes :" )
			np.set_printoptions(threshold=np.nan,edgeitems=9,linewidth=9*16 )
			for k in np.arange(amplitudes.shape[0]) : Print( amplitudes[k] )

		resetNumpyPrintOptions()

	if arguments.verbosity : Print( "\n=> It took : " + str(datetime.now()-startTime) + " to import all " + str( nbTexts ) + " data files.\n" )

	return amplitudes.T

def compareKeys(foundKey,expectedKey) :
	return foundKey[ foundKey == expectedKey ]

def main() :
	global arguments
	parser = initArgs()
	parseMyArguments(parser)
	initAES()

	texts = importTexts()
	printTexts(texts)
	powerTraces = importTraces()

	commonBytes = 0
	if arguments.reverse :
		expectedLastRoundKey = bytearray.fromhex( 'F64E800BD1F9F0A523D54C24AD0297FD' )
#		lastRoundKey = aes_CCA_dec_model( texts, powerTraces, expectedLastRoundKey )
		aes_CCA_model = "aes_CCA_dec_model( texts, powerTraces, expectedLastRoundKey )"
		lastRoundKey = eval( aes_CCA_model )

		Print('\n=> The expected lastRoundKey is ' + byteArray2HexString(expectedLastRoundKey) )

		intersection = compareKeys ( lastRoundKey, expectedLastRoundKey )
#		difference   = np.setdiff1d( lastRoundKey, expectedLastRoundKey ) # 10x plus lent que compareKeys()

		if arguments.verbosity :
			Print('=> lastRoundKey \t = %s' % lastRoundKey)
			Print('=> expectedLastRoundKey  = %s' % expectedLastRoundKey)
			Print('=> Intersection = %s' % intersection )

		commonBytes = intersection.size
		different = keyByteSize - commonBytes
		if not different :
			CPrint('=> The lastRoundKey found is\t' + byteArray2HexString(lastRoundKey), 'blue' )
			CPrint('\n=> Number of bytes in common at the same postion = %d' % commonBytes, 'blue' )
			roundKeys = revertKeyExpension( lastRoundKey )
			if lastRoundKey.size == 16 :
				cipherKey = roundKeys[0]
				CPrint( '\n=> cipherKey = %s' % byteArray2HexString( cipherKey ), 'blue' )
		else :
			CPrint('=> The lastRoundKey found is ' + byteArray2HexString(lastRoundKey) , 'red', attrs=['bold'] )
			CPrint('\n=> Number of bytes in common at the same postion = %d' % commonBytes , 'red', attrs=['bold','blink'] )
	else :
		expectedRound0Key = bytearray.fromhex('0123456789ABCDEF123456789ABCDEF0')

		round0Key = aes_CCA_enc_model( texts, powerTraces, expectedRound0Key )

		Print('\n=> The expected K0 Key is ' + byteArray2HexString(expectedRound0Key) )

		intersection = compareKeys ( round0Key, expectedRound0Key )
#		difference   = np.setdiff1d( round0Key, expectedRound0Key ) # 10x plus lent que compareKeys()

		if arguments.verbosity :
			Print('=> round0Key \t\t = %s' % round0Key)
			Print('=> expectedRound0Key\t = %s' % expectedRound0Key)
			Print('=> Intersection = %s' % intersection )

		commonBytes = intersection.size
		different = keyByteSize - commonBytes
		if not different :
			CPrint('=> The round0Key found is ' + byteArray2HexString(round0Key), 'blue' )
			CPrint('\n=> Number of bytes in common at the same postion = %d' % commonBytes, 'blue' )
		else :
			CPrint('=> The round0Key found is ' + byteArray2HexString(round0Key), 'red', attrs=['bold'] )
			CPrint('\n=> Number of bytes in common at the same postion = %d' % commonBytes, 'red', attrs=['bold','blink'] )

	Print( "\n=> It took : " + str(datetime.now()-startTime) + " to finish the job.\n" )
	Print( "=> with Python version " + pythonVersion + " in " + sys.executable + "\n" )

	Exit()

if __name__ == '__main__': #Appel la fonction main ssi on ne fait pas d'import de ce script
	main()
