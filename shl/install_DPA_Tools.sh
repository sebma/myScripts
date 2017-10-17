#!/usr/bin/env bash

brew=$(which brew)
brewCask="$(which brew) cask"
if [ $(uname -s) = Darwin ]
then
	$brew update
	formulas="watch remake cgdb"
	for formula in $formulas
	do
#		set -x
		$brew list | grep -wq $formula || $brew install $formula
		set +x
	done
	$brew tap caskroom/cask
	$brew tap caskroom/drivers
	$brewCask list | grep -wq mono-mdk || $brewCask install https://raw.githubusercontent.com/caskroom/homebrew-cask/84b7491d6a2c7124fd54ac177cb55f61192018bf/Casks/mono-mdk.rb #Installation de mono-mdk v5.0.1.1
	casks="picoscope arduino"
	for cask in $casks
	do
#		set -x
		$brewCask list | grep -wq $cask || $brewCask install $cask
		set +x
	done
	gem list --local | grep -wq iStats || gem install iStats
elif [ $(uname -s) = Linux ]
then
	echo "=> TO BE DONE."
fi
