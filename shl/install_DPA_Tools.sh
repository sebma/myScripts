#!/usr/bin/env bash

brew="command brew"
brewFormulasToInstall="watch bash python3 gdb git remake"
brewOptionalFormulasToInstall="macvim cgdb octave bash-completion@2 brew-cask-completion pip-completion zsh-completions"

if [ $(uname -s) = Darwin ]
then
	$brew update
	for formula in $brewFormulasToInstall
	do
#		set -x
		$brew list | grep -wq $formula || $brew install $formula
		set +x
	done

	$brew tap caskroom/cask
	$brew tap caskroom/drivers
	$brew tap caskroom/versions
	$brew tap buo/cask-upgrade

	brewCask="command brew cask"
	mono_mdk_V5_0_1_1_Formula_URL="https://raw.githubusercontent.com/caskroom/homebrew-cask/84b7491d6a2c7124fd54ac177cb55f61192018bf/Casks/mono-mdk.rb" #mono-mdk v5.0.1.1 est un pre-requis pour Picoscope6
	brewCaskFormulasToInstall="$mono_mdk_V5_0_1_1_Formula_URL picoscope arduino"

	for cask in $brewCaskFormulasToInstall
	do
#		set -x
		$brewCask list | grep -wq $(basename $cask .rb) || $brewCask install $cask
		set +x
	done
	gem list --local | grep -wq iStats || gem install iStats
elif [ $(uname -s) = Linux ]
then
	echo "=> TO BE DONE."
fi
