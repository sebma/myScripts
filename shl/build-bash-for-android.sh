#!/usr/bin/env bash
#BASH source code from http://ftp.gnu.org/gnu/bash/ 
#Example for compiling bash on Ubuntu 11.04
#Warnings during the compilation process seem to be alright, errors would be bad
BASH_VERSION="bash-4.4"
 
echo "[INFO] Checking if packages installed"
dpkg --status autoconf 2>&1 | grep -q not.installed
if [ $? -eq 0 ]; then
	echo "[INFO] Apt-get installing autoconf, please provide sudo password"
	sudo apt install -V autoconf
else
	echo "[INFO] autoconf already installed, good"
fi
dpkg --status gcc-arm-linux-gnueabi 2>&1 | grep -q not.installed
if [ $? -eq 0 ]; then
	echo "[INFO] Apt-get installing gcc-arm-linux-gnueabi, please provide sudo password"
	sudo apt install -V gcc-arm-linux-gnueabi
else
	echo "[INFO] gcc-arm-linux-gnueabi already installed, good"
fi
echo "[INFO] Starting bash source code download"
wget -P ~/src http://ftp.gnu.org/gnu/bash/$BASH_VERSION.tar.gz
cd ~/src
tar xvfz $BASH_VERSION.tar.gz
cd $BASH_VERSION
CC=`which arm-linux-gnueabi-gcc`
#./configure --host=arm-linux-gnueabi --enable-static-link --without-bash-malloc --enable-largefile --with-readline --with-curses
./configure --host=arm-linux-gnueabi --enable-static-link --without-bash-malloc --enable-largefile --with-readline
make clean
make
file bash | grep -q ARM
if [ ! $? -eq 0 ]; then
	echo "[ERROR] Looks like bash was incorrectly compiled with another compler than arm-linux-gnueabi-gcc"
	echo "[ERROR] The resulting bash binary will not run on ARM, therefore aborting!"
	exit
fi
arm-linux-gnueabi-strip -o bash-stripped -s bash
cp ./bash-stripped ../bash
cd ..
file bash
echo "[INFO] Your bash binary is finished (file 'bash' in current directory), happy autocompleting on ARM!"
