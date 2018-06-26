#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *
print("")

from ipdb import set_trace
import pandas as pda
import numpy as np
import matplotlib.pyplot as plt
import os
from glob import glob
from datetime import datetime

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	import argparse
	class MyFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.MetavarTypeHelpFormatter):
		pass

#	parser = argparse.ArgumentParser( description = 'Regresssion with Keras.', formatter_class = argparse.ArgumentDefaultsHelpFormatter )
	parser = argparse.ArgumentParser( description = 'Regresssion with Keras.', formatter_class = MyFormatter )

	parser.add_argument( "-f", "--firstSample", help="First sample value in the dataSet.", default=0, type=float )
	parser.add_argument( "-L", "--lastSample" , help="Last sample value in the dataSet.",default=1e2, type=float )
	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5, type=float )
	parser.add_argument( "-E", "--earlyStoppingPatience", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-P", "--plotMetrics", help="Enables the live ploting of the trained model metrics in Jupyter NoteBook.", action='store_true', default = False )
	parser.add_argument( "-d", "--dataDIR", help="Datasets directory", default = "../../data", type=str )
	parser.add_argument( "-p", "--pattern", help="Data file name pattern.", default="data*.txt", type=str )
#	parser.add_argument( "-D", "--dumpedModelFileName", help="Dump the model image to fileName", default = None, type=str )
	parser.add_argument( "-S", "--shuffle", help="Shuffle the data along the way.", action='store_true', default = False )
	parser.add_argument( "-V", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-D", "--debug", help="Debug.", action='store_true', default = False )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="relu", choices = ['linear','relu','sigmoid'], type=str )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae','rmse'], type=str )
	parser.add_argument( "-k", "--kernel_initializer", help="NN Model kernel initializer.", default="glorot_uniform", choices = ['glorot_uniform','random_normal','random_uniform'], type=str )
	parser.add_argument( "-O", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam'], type=str )
	parser.add_argument( "-o", "--outputDataframeFileName", help="Datafilename prefix so save the input/output dataframes.", type=str, default = "myData.hdf5" )

	parser.add_argument( "--Lr", help="Set the learning rate of the NN.", default=None, type=float )

	parser.add_argument( "-q", "--quiet", help="Be quiet.", action='store_true', default = False )
	parser.add_argument( "-u", "--usage", help="Print usage.", action='store_true', default = False )
	parser.add_argument( "--mdu", help="Print usage in Markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--mdh",  help="Print help in markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--md", help="Print output in markdown code blocks.", action='store_true', default = False )

	scriptBaseName = parser.prog
	arguments = parser.parse_args()

	if arguments.usage :
		parser.print_usage()
		exit()

	q = arguments.quiet
	if arguments.mdu :
		Print("<pre><code>", quiet = q )
		parser.print_usage()
		Print("</code></pre>", quiet = q )
		exit()

	if arguments.mdh :
		Print("<pre><code>", quiet = q )
		parser.print_help()
		Print("</code></pre>", quiet = q )
		exit()

	if arguments.md : Print("<pre><code>", quiet = q )

	return arguments

def plotDataAndPrediction(df, lossFunctionName, optimizerName) :
	fig = plt.figure( dpi = plotResolution )
#	plt.clf()
	
	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,1)
	plt.title('Regression with <'+lossFunctionName+'> loss and <'+optimizerName+'> optimizer')
	plt.scatter( df[ df.columns[0] ], df[ df.columns[1] ], label='Real data' )
	plt.plot( df[ df.columns[0] ], df['y_predicted'], 'r-.', label='Prediction')
	plt.xlabel( df.columns[0] )
	plt.ylabel( df.columns[1] )
	plt.legend(loc='best')
	
	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,2)
	
#	plt.show()

def initScript() :
	global myArgs, dfX, dfY, plotResolution, pictureFileResolution, nbInputVariables, nbOutputVariables, nbSamples
	global optimizerName, lossFunctionName, myMetrics, modelTrainingCallbacks, dataIsNormalized, monitoredData, fileFormat
	plotResolution = 150
	pictureFileResolution = 600
	yearMonthDay = datetime.today().strftime('%Y%m%d')

	rmse = root_mean_squared_error

	arguments = initArgs()
	Allow_GPU_Memory_Growth()
	pda.options.display.max_rows = 20 #Prints the first max_rows/2 and the last max_rows/2 of each dataframe
	pda.options.display.width = None #Automatically adjust the display width of the terminal

	myArgs = copyArgumentsToStructure( arguments )
	
	prefix =    os.path.splitext( myArgs.outputDataframeFileName )[0]
	extension = os.path.splitext( myArgs.outputDataframeFileName )[1]
	myArgs.outputDataframeFileName = prefix + "_" + yearMonthDay + extension
	fileFormat = extension.strip('.')

	myArgs.epochs = int( myArgs.epochs )
	myArgs.batch_size = int( myArgs.batch_size )

	dfX, dfY = importDataSets()
	nbInputVariables = dfX.columns.size
	nbOutputVariables= dfY.columns.size
	nbSamples = dfX.index.size

	dataIsNormalized = False
	"""
	if myArgs.lossFunction == 'mse' :
		# MSE needs NORMALIZATION
		PrintInfo( "=> Doing Pandas dataframe normalization ..." , quiet = myArgs.quiet )
	#	df[ df.columns[0] ] = keras.utils.normalize( df.values )[:,0]
	#	df[ df.columns[1] ] = keras.utils.normalize( df.values )[:,1]
		dfX = ( dfX-dfX.mean() ) / dfX.std()
		PrintInfo( "=> DONE.\n" , quiet = myArgs.quiet )
		dataIsNormalized = True
"""

	optimizerName = myArgs.optimizer
	lossFunctionName = myArgs.lossFunction.lower()

	if myArgs.lossFunction == 'mse' and myArgs.epochs < 10 : myArgs.epochs = 15

	if myArgs.batch_size == -1 :
		if nbSamples > 1e2 :
			myArgs.batch_size = int(nbSamples / myArgs.epochs)
		else :
			myArgs.batch_size = nbSamples
#			myArgs.epochs = int(nbSamples / 4)

	import keras.optimizers
	if myArgs.Lr :
		if   myArgs.optimizer == 'sgd' :
			myArgs.optimizer = keras.optimizers.sgd(myArgs.Lr)
		elif myArgs.optimizer == 'rmsprop' :
			myArgs.optimizer = keras.optimizers.RMSProp(myArgs.Lr)
		elif myArgs.optimizer == 'adam' :
			myArgs.optimizer = keras.optimizers.Adam(myArgs.Lr)
	
	myMetrics = []
	if   myArgs.lossFunction == 'mae' :
		myMetrics += [ 'mse' ]
		myMetrics += [ rmse ]
	elif myArgs.lossFunction == 'mse' :
		myMetrics += [ rmse ]
		myMetrics += [ 'mae' ]
	elif myArgs.lossFunction == 'rmse' :
		myArgs.lossFunction = rmse
		myMetrics += [ 'mse' ]
		myMetrics += [ 'mae' ]
	#myMetrics += [ 'accuracy' ]

	if myArgs.earlyStoppingPatience == -1 and not myArgs.plotMetrics :
		modelTrainingCallbacks = None
	else :
		modelTrainingCallbacks = []
	
	if myArgs.earlyStoppingPatience != -1 :
		from keras.callbacks import EarlyStopping
		if nbSamples < 10 : monitoredData = 'loss'
		else : monitoredData = 'val_loss'

		modelTrainingCallbacks += [ EarlyStopping( monitor= monitoredData, patience = myArgs.earlyStoppingPatience ) ]
		PrintInfo( "=> The monitored data for early stopping is : " + monitoredData )
		PrintInfo( "=> modelTrainingCallbacks = " + str(modelTrainingCallbacks) )

	if isnotebook() and myArgs.plotMetrics : # The metrics can only be plotted in a jupyter notebook
		from livelossplot import PlotLossesKeras
		modelTrainingCallbacks += [ PlotLossesKeras() ]

def importDataSets() :
	PrintInfo("=> Reading : <%s>\n" %( arguments.dataDIR + os.sep  + arguments.pattern ) )
	cwd = os.getcwd()
	try :
		os.chdir( arguments.dataDIR )

		dataFileList = sorted( glob( arguments.pattern ) )
		nbDataFiles = len(dataFileList)
		nbDataFilesRead = len(dataFileList)

		if not nbDataFilesRead :
			PrintError( "Could not find any "+arguments.pattern+" files, please double check and give the correct data filename pattern." )
			exit( 5 )

		dfX = pda.DataFrame()
		dfY = pda.DataFrame()
		i = 0
		for dataFileName in dataFileList :
			if arguments.verbosity >= 3 : Print( "=> dataFileName = %s" % dataFileName )

			df = pda.read_table( dataFileName, delim_whitespace=True, comment='#' )
			df = df.T
			dfX[i] = df.loc[ df.index[0] ]
			dfY[i] = df.loc[ df.index[1] ]
			i += 1

		dfX = dfX.T
		dfY = dfY.T
	except (Exception,KeyboardInterrupt) as why :
		os.chdir( cwd )
		if isinstance(why, KeyboardInterrupt) :
			PrintError( "KeyboardInterrupt." )
		else :
			PrintError( "Quitting the debugger: %s." % why )
		exit(4)

	os.chdir( cwd )

	return dfX, dfY

def modelDefinition( inputLayerUnits = 1, hiddenLayerUnits = 0, outputLayerUnits = 1 ) :
	from keras.models import Sequential
	from keras.layers import Dense
	import keras.utils, keras.optimizers, keras.initializers
	model = Sequential()
	#First hidden layer
	model.add( Dense( units = hiddenLayerUnits, input_dim = inputLayerUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )
	#Last layer
	model.add( Dense( units = outputLayerUnits ) )

	model.compile( loss=myArgs.lossFunction, optimizer=myArgs.optimizer, metrics = myMetrics )

	return model
	
def main() :
	global nbInputVariables
	initScript()
	if myArgs.outputDataframeFileName :
		saveDataframe( df = dfX, filename = myArgs.outputDataframeFileName, key = 'X', format = fileFormat )
		saveDataframe( df = dfY, filename = myArgs.outputDataframeFileName, key = 'Y', format = fileFormat )


	PrintInfo( "=> nbSamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %d and myArgs.validation_split = %d %%\n" % (nbSamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) , quiet = myArgs.quiet )

	if isnotebook() : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )

	# MODEL DEFINITION
	if not nbInputVariables : nbInputVariables = 5
	model = modelDefinition( inputLayerUnits = nbInputVariables, hiddenLayerUnits = nbInputVariables * 2, outputLayerUnits = nbOutputVariables )

	#MODEL TRAINING
	history = model.fit( dfX, dfY, batch_size=myArgs.batch_size, epochs=myArgs.epochs, validation_split=myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle, verbose = myArgs.verbosity )

	historyDF = pda.DataFrame.from_dict( history.history )
	if myArgs.outputDataframeFileName :
		saveDataframe( df = historyDF,   filename = myArgs.outputDataframeFileName, key = 'history', format = fileFormat )

	if not isnotebook() :
#		plt.rcParams["figure.dpi"]  = plotResolution
#		plt.rcParams['savefig.dpi'] = pictureFileResolution
#		fig = plt.figure( dpi = plotResolution )
		plt.rc( 'figure' , dpi = plotResolution )
		plt.rc( 'savefig', dpi = pictureFileResolution )
		ax = historyDF.plot( ax = plt.gca() )
		ax.set_title('Metrics computed during training')
		ax.set_xlabel('epochs')
		ax.set_ylabel('metrics')
		if myArgs.debug :
			print( historyDF )
#			set_trace()
		plt.grid()
		plt.show()

	nbEpochsDone = historyDF.index.size
	if myArgs.earlyStoppingPatience != -1 :
		PrintInfo( "=> nbEpochsDone = %d\n" % nbEpochsDone )

	PrintInfo( "=> kernel_initializer = <%s>\n" % myArgs.kernel_initializer )

	if myArgs.verbosity or isnotebook() :
		PrintInfo( "=> nbSamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %d and myArgs.validation_split = %d %%\n" % (nbSamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) , quiet = myArgs.quiet )
	
	PrintInfo( "=> Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">\n" , quiet = myArgs.quiet )
	
	dfPredicted = pda.DataFrame( model.predict( dfX ) ) # MODEL PREDICTION

	if myArgs.outputDataframeFileName :
		if myArgs.debug : set_trace()
		saveDataframe( df = dfPredicted, filename = myArgs.outputDataframeFileName, key = 'predictions', format = fileFormat )

#	showModel(model = model, modelFileName = myArgs.dumpedModelFileName, rankdir = 'TB')
	
	if myArgs.Lr : PrintInfo("\n=> lr = ",myArgs.Lr, quiet = myArgs.quiet )
	
	f0 = 191.7
	fStep = 0.05
	fMax= 196
#	plotDataAndPrediction(df, lossFunctionName, optimizerName)
	plt.figure()
	plotExperments( dfX, dfY, fmin = f0, fmax = fMax )
	plt.show( block=True )

	my_keys = sorted( set( globals().keys() ) - orig_keys )
	#print(my_keys)
	Exit(0)

if __name__ == '__main__' : # Calls the main function if (and only if) this script is not imported
	main()
