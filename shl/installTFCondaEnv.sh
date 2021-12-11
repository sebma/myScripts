#!/usr/bin/env bash

function installTFCondaEnv {
	set -o errexit
	set -o nounset

	local os=$(uname -s)
	local -r isAdmin=$(groups | egrep -wq "sudo|adm|admin|root|wheel" && echo true || echo false)
	local shellInitFileName=$HOME/.profile

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

		if ! $CONDA_HOME/bin/conda -h >/dev/null 2>&1
		then
			if [ $(uname -m) = x86_64 ]
			then
				test $os = Linux && minicondaInstallerScript=Miniconda3-latest-Linux-x86_64.sh || minicondaInstallerScript=Miniconda3-latest-MacOS-x86_64.sh
				condaInstallerURL=https://repo.continuum.io/miniconda/$minicondaInstallerScript
				curl -#O $condaInstallerURL
				chmod -v +x $minicondaInstallerScript
				$sudo ./$minicondaInstallerScript -p $CONDA_HOME -b
				test $? = 0 && rm -vi $minicondaInstallerScript
				if ! $CONDA_HOME/bin/conda -h >/dev/null 2>&1
				then
					echo "=> ERROR : miniconda was not successfully installed" >&2
					exit 1
				fi
			fi
		fi

		if ! echo $PATH | grep -q $CONDA_HOME
		then
			echo export CONDA_HOME=$CONDA_HOME
			echo 'export PATH=$CONDA_HOME/bin:$PATH'
		fi >> $shellInitFileName
		export PATH=$CONDA_HOME/bin:$PATH

		CONDA_HOME=$(conda info --root)
		if [ -z $CONDA_HOME ]
		then
			echo "=> ERROR: conda is not in the path." >&2
			exit 2
		fi	

		if env | grep CONDA_DEFAULT_ENV
		then
			echo "conda = $(which conda)"
			echo "=> WARNING: You must be OUTSIDE of the environment to do the rest of the installation, quitting the environment ..." >&2
			source deactivate
			echo "CONDA_DEFAULT_ENV = <$(env | grep CONDA_DEFAULT_ENV)>"
		fi

		conda="command conda"
		echo "conda = $conda"

		$conda list | grep -q argcomplete || $sudo $conda install argcomplete

		echo
		echo "=> Installing tensorflow-gpu conda environment ..."
		echo
		test $# = 1 && tensorFlowEnvName=$1 || tensorFlowEnvName=tensorFlow-GPU
		anacondaModulesList="ipython argcomplete matplotlib numpy pandas pytables pydot scikit-learn keras-gpu"
#		condaForgeModulesList="tensorflow-gpu=1.7.1 namedlist ipdb glances"
		condaForgeModulesList="namedlist ipdb glances"
		$conda env list | grep -q $tensorFlowEnvName || $sudo $conda create -n $tensorFlowEnvName conda python=3 --yes
		$conda env list
		echo "=> BEFORE :"
		$conda list -n $tensorFlowEnvName | egrep "packages in environment|tensorflow|python|$(echo $anacondaModulesList $condaForgeModulesList | tr ' ' '|')"

		pip=$($conda env list | awk "/$tensorFlowEnvName/"'{print$NF"/bin/pip"}')
		echo "=> pip = $pip"

#		tfBinaryURL="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.7.1-cp35-cp35m-linux_x86_64.whl"
#		$pip list | grep -q tensorflow-gpu || $sudo $pip install --ignore-installed --upgrade $tfBinaryURL
		set -x
#		$pip list | grep -q tensorflow-gpu || $sudo $pip install tensorflow-gpu
		$conda list -n $tensorFlowEnvName | grep -q tensorflow-gpu || $sudo $conda install -n $tensorFlowEnvName -c aaronzs tensorflow-gpu
		$sudo $conda install -n $tensorFlowEnvName $anacondaModulesList
		$sudo $conda install -n $tensorFlowEnvName -c conda-forge $condaForgeModulesList
		$sudo $conda install -n $tensorFlowEnvName -c lukepfister scikit.cuda || true
		set +x
		echo "=> AFTER :"
		$conda list -n $tensorFlowEnvName | egrep "packages in environment|tensorflow|python|$(echo $anacondaModulesList $condaForgeModulesList | tr ' ' '|')"

		PyPIPythonModulesList="livelossplot engfmt gpustat"
		for PyPIPythonModule in $PyPIPythonModulesList
		do
			$conda list -n $tensorFlowEnvName | grep -q $PyPIPythonModule || $sudo -H $pip install $PyPIPythonModule
		done

		which gpustat >/dev/null 2>&1 && echo && gpustat -cpu -P
	fi
}

installTFCondaEnv $1
