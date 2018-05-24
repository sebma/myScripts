#!/usr/bin/env bash

function installTFCondaEnv {
	set -o errexit
	set -o nounset

	local os=$(uname -s)
	local -r isAdmin=$(groups | egrep -wq "sudo|adm|admin|root" && echo true || echo false)

	if [ $os = Linux ] || [ $os = Darwin ]
	then
		echo
		echo "=> Installing Miniconda3 ..."
		echo
		if $isAdmin
		then
			sudo="sudo -H"
			CONDA_HOME=/usr/local/miniconda3
			CONDA_ENVS=$CONDA_HOME/envs
		else
			CONDA_HOME=$HOME/miniconda3
			CONDA_ENVS=$HOME/.conda/envs
		fi

		if ! which conda
		then
			if [ $(uname -m) = x86_64 ]
			then
				test $os = Linux && minicondaInstallerScript=Miniconda3-latest-Linux-x86_64.sh || minicondaInstallerScript=Miniconda3-latest-MacOS-x86_64.sh
				condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
				curl -#O $condaInstallerURL
				chmod -v +x $minicondaInstallerScript
				$sudo ./$minicondaInstallerScript -p $CONDA_HOME -b
				test $? = 0 && rm -vi $minicondaInstallerScript
			fi
		fi

		echo $PATH | grep -q $CONDA_HOME || echo 'export PATH=$CONDA_HOME/bin${PATH:+:${PATH}}' >> $shellInitFileName
		conda=$(which conda)
		pip=$(which pip)
		conda list | grep -q argcomplete || $sudo $conda install argcomplete

		echo
		echo "=> Installing tensorflow-gpu conda environment ..."
		echo
		tensorFlowEnvName=$1
		test $tensorFlowEnvName || tensorFlowEnvName=tensorFlow-GPU
		condaForgeModulesList="ipdb glances"
		tensorFlowExtraModulesList="ipython jupyter argcomplete matplotlib numpy pandas scikit-learn keras-gpu"
		conda env list | grep -q $tensorFlowEnvName || $sudo $conda create --prefix $CONDA_ENVS/$tensorFlowEnvName python=3 ipython argcomplete --yes
		conda env list
		echo "=> BEFORE :"
		conda list -n $tensorFlowEnvName | egrep "packages in environment|tensorflow|python|$(echo $tensorFlowExtraModulesList $condaForgeModulesList | tr ' ' '|')"
		set -x
		$sudo $conda install -n $tensorFlowEnvName -c aaronzs tensorflow-gpu --yes
		$sudo $conda install -n $tensorFlowEnvName -c lukepfister scikit.cuda --yes || true
		$sudo $conda install -n $tensorFlowEnvName -c conda-forge $condaForgeModulesList --yes
		$sudo $conda install -n $tensorFlowEnvName $tensorFlowExtraModulesList
		set +x
		echo "=> AFTER :"
		conda list -n $tensorFlowEnvName | egrep "packages in environment|tensorflow|python|$(echo $tensorFlowExtraModulesList $condaForgeModulesList | tr ' ' '|')"

		conda list -n $tensorFlowEnvName | grep gpustat || {
			set -x
			$sudo $pip install --prefix $CONDA_ENVS/$tensorFlowEnvName gpustat
			sudo sed -i '1s|#!.*python|#!'"$CONDA_ENVS/$tensorFlowEnvName/bin/python|" $CONDA_ENVS/$tensorFlowEnvName/bin/gpustat
			set +x
		}

		which gpustat >/dev/null 2>&1 && echo && gpustat -cpu -P
	fi
}

installTFCondaEnv $1
