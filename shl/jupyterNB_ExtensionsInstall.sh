#!/usr/bin/env bash

sudo="sudo -H"
conda=$(which conda)
#pip=$($conda env list | awk "/$tensorFlowEnvName/"'{print$NF}'/bin/pip)
pip=$(which pip)

tensorFlowEnvName=$1
test $tensorFlowEnvName || tensorFlowEnvName=tensorFlow-GPU
condaForgeModulesList="jupyter ipython ipdb jupyter_contrib_nbextensions jupyter_nbextensions_configurator jupyter_latex_envs"
$sudo $conda install -n $tensorFlowEnvName -c conda-forge $condaForgeModulesList
jupyter-contrib nbextension install --user
jupyter-nbextension list
jupyter-nbextension enable toc2/main
jupyter-nbextension enable equation-numbering/main
jupyter-nbextension enable latex_envs/latex_envs
$sudo $pip install git+git://github.com/mkrphys/ipython-tikzmagic.git
