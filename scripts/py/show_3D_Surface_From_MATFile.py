#!/usr/bin/env python
# -*- coding: utf-8 -*-
#MODULES STANDARDS
from __future__ import print_function
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
#MODULES A INSTALLER
import scipy.io as sio #Permet d'importer/exporter des fichiers au format Matlab < 7.3 != hdf5
import matplotlib.pyplot as plt
import mpl_toolkits.mplot3d.axes3d as p3
from matplotlib.ticker import LinearLocator

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'Show 3D surface from MAT file.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument("matLabFile", help="Matlab file to import and display.", type=str)
	scriptBaseName = parser.prog

	arguments = parser.parse_args()

def initScript() :
	pass

def main() :
	initArgs()
	initScript()
	matFileInfo = sio.whosmat( arguments.matLabFile )
	matFileDic  = sio.loadmat( arguments.matLabFile )
	X = matFileDic[ matFileInfo[0][0] ]
	Y = matFileDic[ matFileInfo[1][0] ]
	Z = matFileDic[ matFileInfo[2][0] ]

	fig = plt.figure()
	ax = p3.Axes3D(fig)
	# Customize the z axis.
	#ax.set_zlim(-.3, .7)
	ax.w_zaxis.set_major_locator(LinearLocator(6))

	surface = ax.plot_surface(X, Y, Z, cmap=plt.cm.jet, rstride=1, cstride=1, linewidth=0)

	plt.show()

if __name__ == '__main__': #Appel la fonction main ssi on ne fait pas d'import de ce script
	main()

