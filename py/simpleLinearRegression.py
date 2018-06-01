#!/usr/bin/env python3

orig_keys = set(globals().keys())
from seb_ML import *

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import pandas as pda
import numpy as np
import matplotlib.pyplot as plt

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'Simple Linear Regresssion with Keras.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument( "-n", "--nbSamples", help="Total nbSamples in the dataSet.", default=1e3, type=float )
	parser.add_argument( "-f", "--firstSample", help="First sample value in the dataSet.", default=0, type=float )
	parser.add_argument( "-L", "--lastSample", help="Last sample value in the dataSet.", default=1e2, type=float )
	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5, type=float )
	parser.add_argument( "-E", "--EarlyStopping", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-P", "--PlotMetrics", help="Enables the live ploting of the trained model metrics in Jupyter NoteBook.", action='store_true', default = False )
	parser.add_argument( "-D", "--DumpedModelFileName", help="Dump the model image to fileName", default = None )
	parser.add_argument( "-S", "--Shuffle", help="Shuffle the data along the way.", action='store_true', default = False )
	parser.add_argument( "-v", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="linear", choices = ['linear','relu','sigmoid'] )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae','rmse'] )
	parser.add_argument( "-k", "--kernel_initializer", help="NN Model kernel initializer.", default="glorot_uniform", choices = ['glorot_uniform','random_normal','random_uniform'] )
	parser.add_argument( "-o", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam'] )

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
		Print("<pre><code>")
		parser.print_usage()
		Print("</code></pre>")
		exit()

	if arguments.mdh :
		Print("<pre><code>")
		parser.print_help()
		Print("</code></pre>")
		exit()

	if arguments.md : Print("<pre><code>")

	return arguments

def plotDataAndPrediction(df, lossFunctionName, optimizerName) :
	plt.figure()
	plt.clf()
	
	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,1)
	plt.title('Linear regression with <'+lossFunctionName+'> loss and <'+optimizerName+'> optimizer')
	plt.scatter( df['X_train'], df['y_train'], label='Line' )
	plt.plot( df['X_train'], df['y_predicted'], 'r-.', label='Prediction')
	plt.legend(loc='best')
	
	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,2)
	
	plt.show()

def initScript() :
#	global myArgs, arguments, nbSamples, lastSample, epochs, df, lossFunction, optimizer, activation, Lr, dumpedModelFileName, rmse, batch_size, validation_split, shuffle, earlyStoppingPatience, plotMetrics
	global myArgs, df
	global optimizerName, lossFunctionName, myMetrics, modelTrainingCallbacks, dataIsNormalized

	arguments = initArgs()
	Allow_GPU_Memory_Growth()
	pda.options.display.max_rows = 20 #Prints the first max_rows/2 and the last max_rows/2 of each dataframe

#	from collections import namedtuple # namedtuples are not mutable
	from namedlist import namedlist
	myStruct = namedlist( "myStruct", "nbSamples lastSample epochs lossFunction optimizer activation Lr dumpedModelFileName batch_size validation_split shuffle earlyStoppingPatience plotMetrics kernel_initializer" )

	rmse = RMSE = root_mean_squared_error

	myArgs = myStruct(
						nbSamples = int(arguments.nbSamples),
						lastSample = arguments.lastSample,
						epochs = int(arguments.epochs),
						lossFunction = arguments.lossFunction.lower(),
						optimizer = arguments.optimizer.lower(),
						activation = arguments.activationFunction,
						Lr = arguments.Lr,
						dumpedModelFileName = arguments.DumpedModelFileName,
						batch_size = int(arguments.batch_size),
						validation_split = arguments.validation_split,
						shuffle = arguments.Shuffle,
						earlyStoppingPatience = arguments.EarlyStopping,
						plotMetrics = arguments.PlotMetrics,
						kernel_initializer = arguments.kernel_initializer
					)

	df = pda.DataFrame()
	df['X_train'] = np.linspace(0, myArgs.lastSample, myArgs.nbSamples)
	df['y_train'] = -5 * df['X_train'] + 10

	dataIsNormalized = False
	if myArgs.lossFunction == 'mse' :
		# MSE needs NORMALIZATION
		print( "=> Doing Pandas dataframe normalization ...", file=stderr )
	#	df['X_train'] = keras.utils.normalize( df.values )[:,0]
	#	df['y_train'] = keras.utils.normalize( df.values )[:,1]
		df = ( df-df.mean() ) / df.std()
		print( "=> DONE.", file=stderr )
		dataIsNormalized = True

	optimizerName = myArgs.optimizer
	lossFunctionName = myArgs.lossFunction.lower()

	if myArgs.lossFunction == 'mse' and myArgs.epochs < 10 : myArgs.epochs = 15

	if myArgs.batch_size == -1 :
		if myArgs.nbSamples > 1e2 :
			myArgs.batch_size = int(myArgs.nbSamples / myArgs.epochs)
		else :
			myArgs.batch_size = myArgs.nbSamples
#			myArgs.epochs = int(myArgs.nbSamples / 4)

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
		myMetrics += [ 'rmse' ]
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
		modelTrainingCallbacks += [ EarlyStopping( monitor='val_loss', patience = myArgs.earlyStoppingPatience ) ]
	#	modelTrainingCallbacks += [ EarlyStopping( monitor='loss', patience = myArgs.earlyStoppingPatience ) ]
	if isnotebook() and myArgs.plotMetrics : # The metrics can only be plotted in a jupyter notebook
		from livelossplot import PlotLossesKeras
		modelTrainingCallbacks += [ PlotLossesKeras() ]

def main() :
	global df
	initScript()

	from keras.models import Sequential
	from keras.layers import Dense
	import keras.utils, keras.optimizers, keras.initializers
	
	# MODEL DEFINITION
	model = Sequential()
	model.add( Dense( units=1, input_dim=1, activation = myArgs.activation, kernel_initializer = myArgs.kernel_initializer ) )

	model.compile(loss=myArgs.lossFunction, optimizer=myArgs.optimizer, metrics = myMetrics)

	print( "\n=> myArgs.nbSamples = %d \t myArgs.batch_size = %d \t myArgs.epochs = %d and myArgs.validation_split = %d %%" % (myArgs.nbSamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) )

	if isnotebook() : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )

	#MODEL TRAINING
	history = model.fit( df['X_train'], df['y_train'], batch_size=myArgs.batch_size, epochs=myArgs.epochs, validation_split=myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle )
	
#	mpl.pyplot.ion()
#	print( "=> mpl.is_interactive() = %s" % mpl.is_interactive() )
#	print( "=> matplotlib backend = <%s>" % mpl.get_backend() )
	
	print( "\n=> myArgs.nbSamples = %d \t myArgs.batch_size = %d \t myArgs.epochs = %d and myArgs.validation_split = %d %%" % (myArgs.nbSamples,myArgs.batch_size,myArgs.epochs,int(myArgs.validation_split*100)) )
	
	print( "\n=> Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">" )
	
	slope = model.layers[-1].get_weights()[0].item()
	y_Intercept = model.layers[-1].get_weights()[1].item()
	if dataIsNormalized :
		print("\n=> THE DATA WAS NORMALIZED, hence slope=%.2f\ty_Intercept=%.2f\n" % (slope, y_Intercept))
		df['y_predicted'] = model.predict( df['X_train'] ) # MODEL PREDICTION
	else :
		print("\n=> slope=%.2f\ty_Intercept=%.2f\n" % (slope, y_Intercept))
		df['y_predicted'] = slope*df['X_train'] + y_Intercept
	
	showModel(model = model, modelFileName = myArgs.dumpedModelFileName, rankdir = 'TB')
	
	if myArgs.Lr : print("\n=> lr = ",myArgs.Lr)
	
	plotDataAndPrediction(df, lossFunctionName, optimizerName)

	my_keys = sorted( set( globals().keys() ) - orig_keys )
	#print(my_keys)
	Exit(0)

if __name__ == '__main__' : # Calls the main function if (and only if) this script is not imported
	main()
