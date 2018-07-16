#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *

import pandas as pda
import numpy as np
import matplotlib.pyplot as plt
from ipdb import set_trace

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	import argparse
	class MyFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.MetavarTypeHelpFormatter):
		pass

#	parser = argparse.ArgumentParser( description = 'Simple Linear Regresssion with Keras.', formatter_class = argparse.ArgumentDefaultsHelpFormatter )
	parser = argparse.ArgumentParser( description = 'Simple Linear Regresssion with Keras.', formatter_class = MyFormatter )
	parser.add_argument( "dataFileName", help="(Optional) data fileName to read data from.", nargs='?', type=str )

	parser.add_argument( "-n", "--nbExamples", help="Total nbExamples in the generated dataSet.", default=1e3, type=float )
	parser.add_argument( "-f", "--firstSample", help="First sample value in the dataSet.", default=0, type=float )
	parser.add_argument( "-L", "--lastSample", help="Last sample value in the dataSet.", default=1e2, type=float )
	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5, type=float )
	parser.add_argument( "-E", "--earlyStoppingPatience", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-P", "--plotMetrics", help="Enables the live ploting of the trained model metrics in Jupyter NoteBook.", action='store_true', default = False )
	parser.add_argument( "-d", "--dumpedModelFileName", help="Dump the model image to fileName", default = None, type=str )
	parser.add_argument( "-S", "--shuffle", help="Shuffle the data along the way.", action='store_true', default = False )
	parser.add_argument( "-V", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-D", "--debug", help="Debug.", action='store_true', default = False )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="linear", choices = ['linear','relu','sigmoid'], type=str )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae','rmse'], type=str )
	parser.add_argument( "-k", "--kernel_initializer", help="Initializer for the kernel weights matrix.", default="glorot_uniform", choices = ['glorot_uniform','random_normal','random_uniform','normal'], type=str )
	parser.add_argument( "-O", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam'], type=str )
	parser.add_argument( "-o", "--outputDataframeFileName", help="NN model optimizer algo.", type=str )

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
#	global myArgs, arguments, nbExamples, lastSample, epochs, df, lossFunction, optimizer, activation, Lr, dumpedModelFileName, rmse, batch_size, validation_split, shuffle, earlyStoppingPatience, plotMetrics
	global myArgs, df, plotResolution, pictureFileResolution
	global optimizerName, lossFunctionName, myMetrics, modelTrainingCallbacks, dataIsNormalized, monitoredData
	plotResolution = 150
	pictureFileResolution = 600

	# fix random seed for reproducibility
	seed = 7
	np.random.seed(seed)

	rmse = root_mean_squared_error

	arguments = initArgs()
	Allow_GPU_Memory_Growth()
	pda.options.display.max_rows = 20 #Prints the first max_rows/2 and the last max_rows/2 of each dataframe
	pda.options.display.width = None #Automatically adjust the display width of the terminal

	myArgs = copyArgumentsToStructure( arguments )

	myArgs.nbExamples = int( myArgs.nbExamples )
	myArgs.epochs = int( myArgs.epochs )
	myArgs.batch_size = int( myArgs.batch_size )

	if myArgs.dataFileName :
		df = pda.read_table( myArgs.dataFileName , delim_whitespace=True , comment='#' ) # The column names are infered from the datafile
#		df = pda.read_table('dataset10-nCh10.txt', delim_whitespace=True, comment='#', skiprows=[1,2] ) # To read the data from 'dataset*-nCh*.txt' 		
		myArgs.nbExamples = df.shape[0]
	else :
		X = np.linspace(0, myArgs.lastSample, myArgs.nbExamples)
		df = pda.DataFrame( columns = ['X_train','y_train'] )
		df[ df.columns[0] ] = X
		df[ df.columns[1] ] = -5*X + 10

	dataIsNormalized = False
	if myArgs.lossFunction == 'mse' :
		# MSE needs NORMALIZATION
		PrintInfo( "Doing Pandas dataframe normalization ..." , quiet = myArgs.quiet )
	#	df[ df.columns[0] ] = keras.utils.normalize( df.values )[:,0]
	#	df[ df.columns[1] ] = keras.utils.normalize( df.values )[:,1]
		df = ( df-df.mean() ) / df.std()
		PrintInfo( "DONE." , quiet = myArgs.quiet )
		dataIsNormalized = True

	optimizerName = myArgs.optimizer
	lossFunctionName = myArgs.lossFunction.lower()

	if myArgs.lossFunction == 'mse' and myArgs.epochs < 10 : myArgs.epochs = 15

	if myArgs.batch_size == -1 :
		if myArgs.nbExamples > 1e2 :
			myArgs.batch_size = int(myArgs.nbExamples / myArgs.epochs)
		else :
			myArgs.batch_size = myArgs.nbExamples
#			myArgs.epochs = int(myArgs.nbExamples / 4)

	import keras.optimizers
	if myArgs.Lr :
		if   myArgs.optimizer == 'sgd' :
			myArgs.optimizer = keras.optimizers.sgd(myArgs.Lr)
		elif myArgs.optimizer == 'rmsprop' :
			myArgs.optimizer = keras.optimizers.RMSProp(myArgs.Lr)
		elif myArgs.optimizer == 'adam' :
			myArgs.optimizer = keras.optimizers.Adam(myArgs.Lr)
		elif myArgs.optimizer == 'adadelta' :
			myArgs.optimizer = keras.optimizers.Adadelta( lr = myArgs.Lr )
	
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
		if myArgs.nbExamples < 10 : monitoredData = 'loss'
		else : monitoredData = 'val_loss'

		modelTrainingCallbacks += [ EarlyStopping( monitor= monitoredData, patience = myArgs.earlyStoppingPatience ) ]
		PrintInfo( "The monitored data for early stopping is : " + monitoredData )
		PrintInfo( "modelTrainingCallbacks = " + str(modelTrainingCallbacks) )

	if isnotebook() and myArgs.plotMetrics : # The metrics can only be plotted in a jupyter notebook
		from livelossplot import PlotLossesKeras
		modelTrainingCallbacks += [ PlotLossesKeras() ]

def modelDefinition( inputLayerUnits = 1, hiddenLayerUnits = 1, outputLayerUnits = 1 ) :
	from keras.models import Sequential
	from keras.layers import Dense
	import keras.utils, keras.optimizers, keras.initializers
	model = Sequential()
	#First hidden layer
	model.add( Dense( units = hiddenLayerUnits, input_dim = inputLayerUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )
#	model.add( Dense( units = outputLayerUnits ) ) #Last layer

	model.compile( loss=myArgs.lossFunction, optimizer=myArgs.optimizer, metrics = myMetrics )

	return model

def main() :
	global df
	initScript()

	model = modelDefinition()

	PrintInfo( "\nmyArgs.nbExamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %d and myArgs.validation_split = %d %%" % (myArgs.nbExamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) , quiet = myArgs.quiet )

	if isnotebook() or myArgs.verbosity : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )

	#MODEL TRAINING
	history = model.fit( df[ df.columns[0] ], df[ df.columns[1] ], batch_size=myArgs.batch_size, epochs=myArgs.epochs, validation_split=myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle, verbose = myArgs.verbosity )

	historyDF = pda.DataFrame.from_dict( history.history )
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
			set_trace()
		plt.show()

	nbEpochsDone = historyDF.index.size
	if myArgs.earlyStoppingPatience != -1 :
		PrintInfo( "nbEpochsDone = %d" % nbEpochsDone )

	PrintInfo( "kernel_initializer = " + myArgs.kernel_initializer )

	if myArgs.verbosity or isnotebook() :
		PrintInfo( "\nmyArgs.nbExamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %d and myArgs.validation_split = %d %%" % (myArgs.nbExamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) , quiet = myArgs.quiet )
	
	PrintInfo( "\nLoss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">" , quiet = myArgs.quiet )
	
	slope = model.layers[-1].get_weights()[0].item()
	y_Intercept = model.layers[-1].get_weights()[1].item()
	if dataIsNormalized :
		PrintInfo("\nTHE DATA WAS NORMALIZED, hence slope=%.2f\ty_Intercept=%.2f\n" % (slope, y_Intercept), quiet = myArgs.quiet )
		df['y_predicted'] = model.predict( df[ df.columns[0] ] ) # MODEL PREDICTION
	else :
		PrintInfo("\nslope=%.2f\ty_Intercept=%.2f\n" % (slope, y_Intercept), quiet = myArgs.quiet )
		df['y_predicted'] = slope*df[ df.columns[0] ] + y_Intercept
	
	if myArgs.outputDataframeFileName :
		saveDataframe( df = df, filename = myArgs.outputDataframeFileName )
		saveDataframe( df = historyDF, filename = myArgs.outputDataframeFileName, key = 'history' )

	showModel(model = model, modelFileName = myArgs.dumpedModelFileName, rankdir = 'TB')
	
	if myArgs.Lr : PrintInfo("\nlr = ",myArgs.Lr, quiet = myArgs.quiet )
	
	plotDataAndPrediction(df, lossFunctionName, optimizerName)
	plt.show( block=True )

	my_keys = sorted( set( globals().keys() ) - orig_keys )
	#print(my_keys)
	Exit(0)

if __name__ == '__main__' : # Calls the main function if (and only if) this script is not imported
	main()
