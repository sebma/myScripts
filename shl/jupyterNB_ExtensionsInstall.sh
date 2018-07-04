#!/usr/bin/env bash

trap 'rc=$?;set +x;echo "=> $FUNCNAME: CTRL+C Interruption trapped.">&2;exit $rc' INT
sudo="sudo -H"
conda=$(which conda)
pip=$(which pip)

tensorFlowEnvName=$1
test $tensorFlowEnvName || tensorFlowEnvName=$CONDA_DEFAULT_ENV
condaForgeModulesList="jupyter ipython ipdb jupyter_contrib_nbextensions jupyter_nbextensions_configurator jupyter_latex_envs jupyterlab jupyterhub"

set -x
$sudo $conda install -n $tensorFlowEnvName -c conda-forge $condaForgeModulesList
$conda list -n $tensorFlowEnvName | grep -q jupyter_contrib_nbextensions && {
jupyter-contrib nbextension install --user
jupyter-nbextension list
jupyter-nbextension enable toc2/main
jupyter-nbextension enable equation-numbering/main
jupyter-nbextension enable latex_envs/latex_envs
$sudo $pip install git+git://github.com/mkrphys/ipython-tikzmagic.git
}
trap - INT
