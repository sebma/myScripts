#!/usr/bin/env bash

set -o nounset
set -o errexit

trap 'rc=$?;set +x;echo "=> $0: CTRL+C Interruption trapped.">&2;exit $rc' INT

test $# = 1 && condaEnvName=$1 || condaEnvName=tensorFlow-GPU

sudo="sudo -H"

condaForgeModulesList="jupyter ipython ipdb jupyter_contrib_nbextensions jupyter_nbextensions_configurator jupyter_latex_envs jupyterlab jupyterhub"

if env | grep CONDA_DEFAULT_ENV
then
	echo "conda = $(which conda)"
	echo "=> WARNING: You must be OUTSIDE of the environment to do the rest of the installation, quitting the environment ..." >&2
	source deactivate
	echo "CONDA_DEFAULT_ENV = <$(env | grep CONDA_DEFAULT_ENV)>"
fi

conda="command conda"
echo "conda = $conda"
pip=$($conda env list | awk "/$condaEnvName/"'{print$NF"/bin/pip"}')

set -x
$sudo $conda install -n $condaEnvName -c conda-forge $condaForgeModulesList
$conda list -n $condaEnvName | grep -q jupyter_contrib_nbextensions && {
jupyter-contrib nbextension install --user 2>/dev/null
jupyter-nbextension list
jupyter-nbextension enable toc2/main
jupyter-nbextension enable equation-numbering/main
jupyter-nbextension enable latex_envs/latex_envs
$sudo $pip install git+git://github.com/mkrphys/ipython-tikzmagic.git
}
trap - INT
