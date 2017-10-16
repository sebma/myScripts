#!/usr/bin/env bash

brew=$(which brew)
if [ $(uname -s) = Darwin ]
then
	set -x
	$brew update
	$brew install watch remake cgdb
	$brew tap caskroom/cask
	$brew tap caskroom/drivers
	$brew cask install https://raw.githubusercontent.com/caskroom/homebrew-cask/84b7491d6a2c7124fd54ac177cb55f61192018bf/Casks/mono-mdk.rb #Installation de mono-mdk v5.0.1.1
	$brew cask install picoscope arduino
	gem install iStats
elif [ $(uname -s) = Linux ]
then
	echo "=> TO BE DONE."
fi
